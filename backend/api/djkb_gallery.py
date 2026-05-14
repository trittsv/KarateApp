import re
from urllib.parse import urljoin

import requests

from config import DJKB_BASE_URL, DJKB_HEADERS, REQUEST_TIMEOUT_SECONDS
from html_utils import absolutize, find_href, find_raw, find_text, html_decode


def load_gallery_years():
    response = requests.get(urljoin(DJKB_BASE_URL, "/bilder/2026/"), headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    result = []
    seen = set()
    for match in re.finditer(r'<a[^>]+href="(/bilder/(\d{4})/)"[^>]*>\s*\2\s*</a>', response.text):
        url = absolutize(match.group(1))
        if url in seen:
            continue
        seen.add(url)
        result.append({"title": match.group(2), "url": url})
    return result


def load_gallery_albums(url: str):
    response = requests.get(url, headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    result = []
    for match in re.finditer(
        r'<div class="row list-item">(.*?)</div>\s*</div>\s*</div>',
        response.text,
        flags=re.S,
    ):
        item_html = match.group(1)
        album_url = absolutize(find_href(item_html, r'class="image-container"[^>]*>\s*<a href="([^"]+)"'))
        if not album_url:
            continue
        result.append({
            "title": find_text(item_html, r'class="headline"[^>]*>.*?<a[^>]*>(.*?)</a>'),
            "description": find_text(item_html, r'class="description"[^>]*>(.*?)</div>'),
            "url": album_url,
            "thumbnail_url": absolutize(find_href(item_html, r'class="image-container"[^>]*>.*?<img[^>]+src="([^"]+)"')),
            "item_count": int(find_raw(item_html, r'class="image-count"[^>]*>\s*(\d+)') or "0"),
        })
    return result


def load_gallery_photos(url: str):
    response = requests.get(url, headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    photos = []
    for match in re.finditer(
        r'<a href="([^"]+)"[^>]*data-gallery[^>]*>\s*<img[^>]+src="([^"]+)"',
        response.text,
        flags=re.S,
    ):
        image_url = absolutize(html_decode(match.group(1)))
        photos.append({
            "url": image_url,
            "image_url": image_url,
            "thumbnail_url": absolutize(html_decode(match.group(2))),
        })
    next_url = absolutize(find_href(
        response.text,
        r'<li class="next"[^>]*>\s*<a[^>]+href="([^"]+)"',
    ))
    return {"items": photos, "next_url": next_url, "has_more": bool(next_url)}
