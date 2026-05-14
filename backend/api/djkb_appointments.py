import re
from urllib.parse import parse_qs, unquote_plus, urljoin, urlparse

import requests

from config import DJKB_BASE_URL, DJKB_HEADERS, REQUEST_TIMEOUT_SECONDS
from geocoding import cached_geocode_location
from html_utils import absolutize, find_href, find_raw, find_text, html_decode


APPOINTMENT_LIMIT = 9
APPOINTMENT_SOURCES = [
    ("/termine/lehrgangs-termine", "seminar"),
    ("/termine/wettkampf-termine", "competition"),
    ("/termine/bundeskader-termine", "national_team"),
    ("/termine/stuetzpunktkader-termine", "regional_team"),
    ("/termine/ausbildungs-termine", "training"),
]


def extract_location(maps_url: str, fallback_city: str):
    parsed = urlparse(maps_url or "")
    query = parse_qs(parsed.query).get("q", [""])[0]
    query = " ".join(unquote_plus(query).split())

    street = ""
    zip_code = ""
    city = fallback_city.strip()

    match = re.search(r"\b\d{5}\b", query)
    if match:
        zip_code = match.group(0)
        street = query[:match.start()].strip()
        city = query[match.end():].strip() or fallback_city.strip()
    elif query:
        city = query

    return {
        "street": street,
        "zip": zip_code,
        "city": city,
        "country": "Germany",
        "maps_url": maps_url,
    }


def parse_appointment_cards(html: str, event_type: str):
    cards = []
    for match in re.finditer(
        r'<div class="card-wrapper">(.*?)(?=<div class="card-wrapper">|<div class="rest"|$)',
        html,
        flags=re.S,
    ):
        card = match.group(1)
        location_text = find_text(
            card,
            r'class="map-wrapper"[^>]*>.*?<span>(.*?)</span>',
        ).replace("(Maps)", "").strip()
        maps_url = absolutize(find_href(
            card,
            r'class="map-wrapper"[^>]*>.*?<a href="([^"]+)"',
        ))
        ics_url = absolutize(find_href(
            card,
            r'class="calendar-wrapper"[^>]*>.*?<a[^>]+href="([^"]+)"',
        ))
        appointment_id = parse_qs(urlparse(ics_url).query).get(
            "tx_djkbmanager_appointmentscreateics[appointment]",
            [""],
        )[0]

        location = extract_location(maps_url, location_text)
        cached_geocode_location(location)

        cards.append({
            "event_type": event_type,
            "date": find_text(card, r'class="date-container"[^>]*>(.*?)</div>'),
            "category": find_text(card, r'class="category-container[^"]*"[^>]*>(.*?)</div>'),
            "title": find_text(card, r'class="appointment-title"[^>]*>(.*?)</div>'),
            "dojo": find_text(card, r'class="contact-dojoname"[^>]*>(.*?)</div>'),
            "contact": find_text(card, r'class="contact-name"[^>]*>(.*?)</div>'),
            "email": find_href(card, r'href="mailto:([^"]+)"'),
            "phone": find_href(card, r'href="tel:([^"]+)"'),
            "location": location,
            "pdf_url": absolutize(find_href(card, r'class="pdf-wrapper"[^>]*>.*?<a href="([^"]+)"')),
            "ics_url": ics_url,
            "appointment_id": appointment_id,
        })
    return cards


def fetch_appointment_source(path: str, event_type: str):
    current_page = urljoin(DJKB_BASE_URL, path)
    response = requests.get(current_page, headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    html = response.text

    ajax_path = html_decode(find_raw(html, r'id="ajax-url"[^>]*data-ajaxurl="([^"]+)"'))
    if not ajax_path:
        return []

    ajax_url = urljoin(DJKB_BASE_URL, ajax_path)
    inputs = dict(re.findall(r'<input[^>]+name="([^"]+)"[^>]*value="([^"]*)"', html, flags=re.S))
    inputs = {html_decode(key): html_decode(value) for key, value in inputs.items()}
    rows = []
    offset = 0

    while True:
        rows.extend(parse_appointment_cards(html, event_type))
        rest_match = re.search(r'class="rest"[^>]*data-rest="(\d+)"', html, flags=re.S)
        rest = int(rest_match.group(1)) if rest_match else 0
        if rest <= 0:
            break

        offset += APPOINTMENT_LIMIT
        inputs["tx_djkbmanager_appointmentslist[offset]"] = str(offset)
        response = requests.post(
            ajax_url,
            data=inputs,
            headers={**DJKB_HEADERS, "Referer": current_page, "X-Requested-With": "XMLHttpRequest"},
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        html = response.text

    return rows


def dedupe_appointments(items):
    seen = set()
    result = []
    for item in items:
        appointment_id = item.get("appointment_id") or ""
        key = (
            f"{item.get('event_type')}|{appointment_id}"
            if appointment_id
            else "|".join([
                item.get("event_type", ""),
                item.get("date", ""),
                item.get("title", ""),
                item.get("ics_url", ""),
                item.get("pdf_url", ""),
            ])
        )
        if key in seen:
            continue
        seen.add(key)
        result.append(item)
    return result


def load_appointments():
    items = []
    for path, event_type in APPOINTMENT_SOURCES:
        items.extend(fetch_appointment_source(path, event_type))
    return dedupe_appointments(items)
