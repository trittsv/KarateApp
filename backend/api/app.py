import hmac
import html
import os

from flask import Flask, Response, jsonify, redirect, render_template, request, send_from_directory

from config import ADMIN_PASSWORD, ADMIN_USERNAME, LOCATIONIQ_API_KEY
from djkb_appointments import load_appointments
from djkb_dojos import load_dojos
from djkb_gallery import load_gallery_albums, load_gallery_photos, load_gallery_years
from djkb_news import load_news, load_news_detail
from geocoding import (
    clear_geocode_cache,
    geocoding_status,
    geocode_query,
    normalize_query,
)
from access_statistics import access_summary, record_access
from ram_cache import (
    cached_or_load,
    enrich_appointment_coordinates,
    enrich_dojo_coordinates,
)


APP = Flask(__name__)
PROTECTED_PATHS = {
    "/admin",
    "/admin/geocode-cache/clear",
    "/stats",
    "/geocode/status"
}


def unauthorized_response():
    return Response(
        "Authentication required\n",
        401,
        {
            "WWW-Authenticate": 'Basic realm="Karate App Backend"',
        },
    )


def valid_admin_credentials(username: str, password: str) -> bool:
    if not ADMIN_USERNAME or not ADMIN_PASSWORD:
        return False

    return (
        hmac.compare_digest(username or "", ADMIN_USERNAME)
        and hmac.compare_digest(password or "", ADMIN_PASSWORD)
    )


@APP.before_request
def protect_admin_pages():
    if request.path not in PROTECTED_PATHS:
        return None

    authorization = request.authorization
    if authorization is None:
        return unauthorized_response()

    if not valid_admin_credentials(authorization.username, authorization.password):
        return unauthorized_response()

    return None


@APP.after_request
def record_request_statistics(response):
    try:
        record_access(
            path=request.path,
            platform=request.headers.get("X-KarateApp-Platform", ""),
        )
    except Exception:
        APP.logger.exception("failed to record access statistics")

    return response


@APP.get("/")
def home():
    mobile_downloads = [
        {
            "label": "Android",
            "detail": "Google Play",
            "url": os.environ.get(
                "KARATEAPP_ANDROID_STORE_URL",
                "https://play.google.com/store/apps/details?id=trittsv.app.karateapp",
            ),
        },
        {
            "label": "iOS",
            "detail": "App Store",
            "url": os.environ.get("KARATEAPP_IOS_STORE_URL", ""),
        },
    ]
    return render_template(
        "home.html",
        active_page="downloads",
        mobile_downloads=mobile_downloads,
    )


@APP.get("/admin")
def admin():
    status = geocoding_status()
    stats = access_summary()
    return render_template("admin.html", stats=stats, status=status)


@APP.get("/health")
def health():
    return jsonify({
        "ok": True,
        "locationiq_configured": bool(LOCATIONIQ_API_KEY),
        "geocoding": geocoding_status(),
    })


@APP.get("/privacy")
def privacy_policy():
    return render_template("privacy.html", active_page="privacy")


@APP.get("/datenschutz")
@APP.get("/datenschutz.html")
@APP.get("/privacy.html")
def privacy_policy_redirect():
    return redirect("/privacy", code=301)


@APP.get("/imprint")
def imprint():
    return render_template("imprint.html", active_page="imprint")


@APP.get("/impressum")
@APP.get("/impressum.html")
@APP.get("/imprint.html")
def imprint_redirect():
    return redirect("/imprint", code=301)


@APP.get("/support")
def support():
    return render_template("support.html", active_page="support")


@APP.get("/hilfe")
@APP.get("/support.html")
def support_redirect():
    return redirect("/support", code=301)


@APP.get("/static/store/<path:filename>")
def store_asset(filename):
    return send_from_directory("../../res/store/google-play", filename)


@APP.get("/favicon.ico")
def favicon():
    return send_from_directory(
        "../../res/store/google-play",
        "google-play-icon-512.png",
        mimetype="image/png",
    )


@APP.get("/apple-touch-icon.png")
def apple_touch_icon():
    return send_from_directory(
        "../../res/store/google-play",
        "google-play-icon-512.png",
        mimetype="image/png",
    )


@APP.get("/appointments")
def appointments():
    try:
        items, cached = cached_or_load(
            "appointments",
            load_appointments,
            enrich_appointment_coordinates,
        )
        if cached:
            APP.logger.info("returning appointments from RAM cache: %s items", len(items))
        return jsonify(items)
    except Exception as error:
        APP.logger.exception("failed to load appointments")
        return jsonify({
            "error": "appointments_failed",
            "message": str(error),
        }), 502


@APP.get("/dojos")
def dojos():
    APP.logger.info("started loading dojos")
    try:
        items, cached = cached_or_load(
            "dojos",
            load_dojos,
            enrich_dojo_coordinates,
        )
        if cached:
            APP.logger.info("returning dojos from RAM cache: %s items", len(items))
        APP.logger.info("finished loading dojos: %s items", len(items))
        return jsonify(items)
    except Exception as error:
        APP.logger.exception("failed to load dojos")
        return jsonify({
            "error": "dojos_failed",
            "message": str(error),
        }), 502


@APP.get("/news")
def news():
    try:
        return jsonify(load_news(
            request.args.get("section", "news"),
            request.args.get("token", ""),
        ))
    except Exception as error:
        APP.logger.exception("failed to load news")
        return jsonify({"error": "news_failed", "message": str(error)}), 502


@APP.get("/news/detail")
def news_detail():
    url = request.args.get("url", "").strip()
    if not url:
        return jsonify({"error": "missing_url"}), 400
    try:
        return jsonify(load_news_detail(url))
    except Exception as error:
        APP.logger.exception("failed to load news detail")
        return jsonify({"error": "news_detail_failed", "message": str(error)}), 502


@APP.get("/gallery/years")
def gallery_years():
    try:
        return jsonify(load_gallery_years())
    except Exception as error:
        APP.logger.exception("failed to load gallery years")
        return jsonify({"error": "gallery_years_failed", "message": str(error)}), 502


@APP.get("/gallery/albums")
def gallery_albums():
    url = request.args.get("url", "").strip()
    if not url:
        return jsonify({"error": "missing_url"}), 400
    try:
        return jsonify(load_gallery_albums(url))
    except Exception as error:
        APP.logger.exception("failed to load gallery albums")
        return jsonify({"error": "gallery_albums_failed", "message": str(error)}), 502


@APP.get("/gallery/photos")
def gallery_photos():
    url = request.args.get("url", "").strip()
    if not url:
        return jsonify({"error": "missing_url"}), 400
    try:
        return jsonify(load_gallery_photos(url))
    except Exception as error:
        APP.logger.exception("failed to load gallery photos")
        return jsonify({"error": "gallery_photos_failed", "message": str(error)}), 502


@APP.get("/geocode")
def geocode():
    query = request.args.get("q", "").strip()
    fallback_query = request.args.get("fallback", "").strip()
    normalized_query = normalize_query(query)

    if not normalized_query:
        return jsonify({
            "found": False,
            "error": "missing_query",
        }), 400

    result = geocode_query(query)
    if result is None and normalize_query(fallback_query):
        result = geocode_query(fallback_query)

    if result is None:
        return jsonify({
            "query": query,
            "normalized_query": normalized_query,
            "found": False,
            "latitude": None,
            "longitude": None,
            "display_name": "",
        })

    result.setdefault("query", query)
    result.setdefault("normalized_query", normalized_query)
    result.setdefault("cached", False)
    return jsonify(result)


@APP.get("/geocode/status")
def geocode_status():
    return jsonify(geocoding_status())


@APP.post("/admin/geocode-cache/clear")
def clear_geocode_cache_route():
    deleted_count = clear_geocode_cache()
    return Response(f"""<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Geocode cache cleared</title>
</head>
<body>
    <h1>Geocode cache cleared</h1>
    <p>Deleted rows: {deleted_count}</p>
    <p><a href="/">Back to dashboard</a></p>
</body>
</html>
""", mimetype="text/html")


@APP.get("/stats")
def stats():
    return jsonify(access_summary())


if __name__ == "__main__":
    APP.run(host="0.0.0.0", port=int(os.environ.get("PORT", "5042")))
