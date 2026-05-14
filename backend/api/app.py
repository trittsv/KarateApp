import hmac
import html
import os

from flask import Flask, Response, jsonify, request

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
    "/",
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
            client_id=request.headers.get("X-KarateApp-Client-Id", ""),
        )
    except Exception:
        APP.logger.exception("failed to record access statistics")

    return response


@APP.get("/")
def index():
    status = geocoding_status()
    stats = access_summary()
    geocoding_text = "yes" if status["geocoding"] else "no"
    waiting_text = "yes" if status["waiting"] else "no"
    current_query = html.escape(status["current_query"] or "-")
    platform_rows = "\n".join(
        f"<tr><td>{html.escape(row['platform'])}</td><td>{row['users']}</td><td>{row['requests']}</td></tr>"
        for row in stats["by_platform"]
    ) or "<tr><td colspan=\"3\">No app requests yet</td></tr>"
    path_rows = "\n".join(
        f"<tr><td>{html.escape(row['path'])}</td><td>{row['count']}</td></tr>"
        for row in stats["by_path"][:8]
    ) or "<tr><td colspan=\"2\">No app requests yet</td></tr>"
    return Response(f"""<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="3">
    <title>Karate App Backend</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 2rem; line-height: 1.45; }}
        header {{ display: flex; align-items: center; justify-content: space-between; gap: 1rem; }}
        .badge {{ display: inline-block; padding: .2rem .55rem; border-radius: 999px; background: #eee; }}
        .active {{ background: #ffe0e0; color: #9b111e; }}
        dl {{ display: grid; grid-template-columns: max-content 1fr; gap: .4rem 1rem; }}
        dt {{ font-weight: 600; }}
        table {{ border-collapse: collapse; min-width: min(100%, 42rem); margin: 1rem 0 2rem; }}
        th, td {{ border-bottom: 1px solid #e4e4e7; padding: .55rem .7rem; text-align: left; }}
        th {{ background: #f7f7f9; }}
        button {{ border: 1px solid #d4d4d8; border-radius: .55rem; background: #fff; padding: .55rem .8rem; cursor: pointer; }}
        button.danger {{ color: #9b111e; border-color: #f3b6bd; background: #fff5f5; }}
    </style>
</head>
<body>
    <header>
        <h1>Karate App Backend</h1>
    </header>
    <h2>Usage</h2>
    <dl>
        <dt>Users total</dt><dd>{stats["total_users"]}</dd>
        <dt>Users last 24h</dt><dd>{stats["last_24h_users"]}</dd>
        <dt>Requests total</dt><dd>{stats["total_requests"]}</dd>
        <dt>Requests last 24h</dt><dd>{stats["last_24h_requests"]}</dd>
    </dl>
    <h2>Devices</h2>
    <table>
        <thead><tr><th>Platform</th><th>Users</th><th>Requests</th></tr></thead>
        <tbody>{platform_rows}</tbody>
    </table>
    <h2>Top endpoints</h2>
    <table>
        <thead><tr><th>Path</th><th>Requests</th></tr></thead>
        <tbody>{path_rows}</tbody>
    </table>
    <h2>Geocoding</h2>
    <p class="badge {'active' if status["geocoding"] else ''}">Geocoding: {geocoding_text}</p>
    <dl>
        <dt>Waiting</dt><dd>{waiting_text}</dd>
        <dt>Active requests</dt><dd>{status["active_requests"]}</dd>
        <dt>Waiting requests</dt><dd>{status["waiting_requests"]}</dd>
        <dt>Current query</dt><dd>{current_query}</dd>
        <dt>Last started</dt><dd>{status["last_started_at"] or "-"}</dd>
        <dt>Last finished</dt><dd>{status["last_finished_at"] or "-"}</dd>
    </dl>
    <form method="post" action="/admin/geocode-cache/clear">
        <button class="danger" type="submit">Clear geocode cache</button>
    </form>
    <p><a href="/health">Health</a> · <a href="/geocode/status">Geocode status JSON</a> · <a href="/stats">Stats JSON</a></p>
</body>
</html>
""", mimetype="text/html")


@APP.get("/health")
def health():
    return jsonify({
        "ok": True,
        "locationiq_configured": bool(LOCATIONIQ_API_KEY),
        "geocoding": geocoding_status(),
    })


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
