import re
import logging
from urllib.parse import urljoin

import requests

from config import DJKB_BASE_URL, DJKB_HEADERS, REQUEST_TIMEOUT_SECONDS
from geocoding import cached_geocode_location
from html_utils import absolutize, find_href, find_raw, html_decode, strip_tags


def load_dojos():
    dojos_url = urljoin(DJKB_BASE_URL, "/jka-in-deutschland/djkb-dojos/")
    logging.info("fetching dojo page: %s", dojos_url)
    response = requests.get(dojos_url, headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    html = response.text

    ajax_path = html_decode(find_raw(html, r'id="ajax-url"[^>]*data-ajaxurl="([^"]+)"'))
    ajax_url = urljoin(DJKB_BASE_URL, ajax_path)
    logging.info("fetching dojo ajax page: %s", ajax_url)
    response = requests.post(
        ajax_url,
        data={
            "tx_djkbmanager_dojoslist[offset]": "0",
            "tx_djkbmanager_dojoslist[limit]": "500",
        },
        headers={**DJKB_HEADERS, "Content-Type": "application/x-www-form-urlencoded"},
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    logging.info("dojo ajax response loaded")

    result = []
    for match in re.finditer(
        r'<div class="dojo-item">(.*?)(?=<div class="dojo-item">|<div class="rest")',
        response.text,
        flags=re.S,
    ):
        item_html = match.group(1)
        title = strip_tags(find_raw(item_html, r'<div class="dojo-title">(.*?)</div>'))
        if not title:
            continue

        street = strip_tags(find_raw(item_html, r'class="dojo-address-data"[^>]*>\s*<span>(.*?)</span>'))
        zip_city = strip_tags(find_raw(item_html, r'class="dojo-address-data"[^>]*>.*?<span>.*?</span>\s*<span>(.*?)</span>'))
        dojo = {
            "title": title,
            "street": street,
            "zip_city": zip_city,
            "website": find_href(item_html, r'class="dojo-website"[^>]*>.*?<a[^>]*href="([^"]+)"'),
            "email": find_href(item_html, r'class="contact-mail"[^>]*>.*?<a[^>]*href="mailto:([^"]+)"'),
            "phone": find_href(item_html, r'class="contact-phone"[^>]*>.*?<a[^>]*href="tel:([^"]+)"'),
            "contact": strip_tags(find_raw(item_html, r'class="contact-name"[^>]*>(.*?)</div>'))
                       or strip_tags(find_raw(item_html, r'class="contact-rte"[^>]*>(.*?)</div>')),
            "notes": strip_tags(find_raw(item_html, r'class="modal-body"[^>]*>(.*?)</div>')),
            "image_url": absolutize(find_href(item_html, r'class="image-container"[^>]*>.*?<img[^>]*src="([^"]+)"')),
        }
        geocode_location = {
            "street": street,
            "zip": "",
            "city": zip_city,
        }
        cached_geocode_location(geocode_location)
        dojo["latitude"] = geocode_location.get("latitude")
        dojo["longitude"] = geocode_location.get("longitude")
        dojo["has_coordinate"] = geocode_location["has_coordinate"]
        result.append(dojo)

    logging.info("parsed dojos: %s", len(result))
    return result
