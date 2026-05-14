import re
from urllib.parse import parse_qs, urlencode, urljoin

import requests

from config import DJKB_BASE_URL, DJKB_HEADERS, REQUEST_TIMEOUT_SECONDS
from html_utils import absolutize, find_href, find_raw, find_text, html_decode


def parse_news_page(html: str):
    articles = []
    for match in re.finditer(
        r'<div class="article [^"]*"[^>]*>(.*?)(?=<div class="article [^"]*"|<div class="load-more-wrapper"|</div>\s*</div>\s*<script>)',
        html,
        flags=re.S,
    ):
        article = match.group(1)
        item = {
            "item_type": "news",
            "url": absolutize(find_href(article, r'class="news-item-link"[^>]*href="([^"]+)"')),
            "image_url": absolutize(find_href(article, r'class="image-container"[^>]*>.*?<img[^>]*src="([^"]+)"')),
            "date": find_text(article, r"<time[^>]*>(.*?)</time>"),
            "title": find_text(article, r'itemprop="headline"[^>]*>(.*?)</span>'),
            "description": find_text(article, r'class="description"[^>]*>(.*?)</div>'),
        }
        if item["title"]:
            articles.append(item)

    next_url = absolutize(find_href(
        html,
        r'<li class="next"[^>]*>\s*<a[^>]*href="([^"]+)"',
    ))
    return articles, next_url


def parse_results_form(html: str):
    ajax_url = absolutize(find_href(html, r'id="ajax-url"[^>]*data-ajaxurl="([^"]+)"'))
    form_html = find_raw(html, r'<form[^>]+id="resultsSearchForm"[^>]*>(.*?)</form>')
    form = {
        html_decode(key): html_decode(value)
        for key, value in re.findall(
            r'<input[^>]+name="([^"]+)"[^>]*value="([^"]*)"',
            form_html,
            flags=re.S,
        )
    }
    return ajax_url, form


def parse_results_page(html: str):
    articles = []
    for match in re.finditer(
        r'<div class="card-wrapper">(.*?)(?=<div class="card-wrapper">|<div class="rest"|$)',
        html,
        flags=re.S,
    ):
        card = match.group(1)
        pdf_url = absolutize(find_href(card, r'class="pdf-wrapper"[^>]*>.*?<a[^>]+href="([^"]+)"'))
        title = find_text(card, r'class="result-title"[^>]*>(.*?)</div>')
        if not title or not pdf_url:
            continue

        contact = find_text(card, r'class="contact-name"[^>]*>(.*?)</div>')
        articles.append({
            "item_type": "result",
            "title": title,
            "date": find_text(card, r'class="date-container"[^>]*>(.*?)</div>'),
            "category": find_text(card, r'class="category-container[^"]*"[^>]*>(.*?)</div>'),
            "description": f"Ansprechpartner: {contact}" if contact else "",
            "url": pdf_url,
            "image_url": "",
        })

    rest = int(find_raw(html, r'class="rest"[^>]*data-rest="(\d+)"') or "0")
    return articles, rest > 0


def load_news(section: str, token: str):
    section = "results" if section == "results" else "news"
    if section == "results":
        first_url = urljoin(DJKB_BASE_URL, "/aktuelles/wettkampfergebnisse/")
        if token:
            token_data = parse_qs(token)
            ajax_url = token_data.get("ajax_url", [""])[0]
            offset = int(token_data.get("offset", ["0"])[0])
            form = {key[5:]: value[0] for key, value in token_data.items() if key.startswith("form_")}
            form["tx_djkbmanager_resultslist[offset]"] = str(offset)
            response = requests.post(
                ajax_url,
                data=form,
                headers={**DJKB_HEADERS, "X-Requested-With": "XMLHttpRequest"},
                timeout=REQUEST_TIMEOUT_SECONDS,
            )
        else:
            response = requests.get(first_url, headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
        response.raise_for_status()
        html = response.text

        if token:
            token_data = parse_qs(token)
            ajax_url = token_data.get("ajax_url", [""])[0]
            offset = int(token_data.get("offset", ["0"])[0])
            form = {key[5:]: value[0] for key, value in token_data.items() if key.startswith("form_")}
        else:
            ajax_url, form = parse_results_form(html)
            offset = 0

        items, has_more = parse_results_page(html)
        next_token = ""
        if has_more and ajax_url:
            next_offset = offset + int(form.get("tx_djkbmanager_resultslist[limit]", "9") or "9")
            token_pairs = [("ajax_url", ajax_url), ("offset", str(next_offset))]
            token_pairs.extend((f"form_{key}", value) for key, value in form.items())
            next_token = urlencode(token_pairs)
        return {"items": items, "next_token": next_token, "has_more": bool(next_token)}

    url = token or urljoin(DJKB_BASE_URL, "/aktuelles/aktuelle-meldungen/")
    response = requests.get(url, headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    items, next_url = parse_news_page(response.text)
    return {"items": items, "next_token": next_url, "has_more": bool(next_url)}


def load_news_detail(url: str):
    response = requests.get(url, headers=DJKB_HEADERS, timeout=REQUEST_TIMEOUT_SECONDS)
    response.raise_for_status()
    detail_html = find_raw(response.text, r'<div class="modal-content">(.*?)<div class="modal-footer')
    images = [
        absolutize(html_decode(match.group(1)))
        for match in re.finditer(
            r'class="news-media-container"[^>]*>.*?<img[^>]*src="([^"]+)"',
            detail_html,
            flags=re.S,
        )
    ]
    return {
        "title": find_text(detail_html, r'id="newsItemTitle"[^>]*>(.*?)</h1>'),
        "date": find_text(detail_html, r"<time[^>]*>(.*?)</time>"),
        "body": find_text(detail_html, r'itemprop="articleBody"[^>]*>(.*?)</div>'),
        "images": images,
    }
