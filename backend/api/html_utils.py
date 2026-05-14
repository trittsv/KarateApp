import re
from html import unescape
from urllib.parse import urljoin

from config import DJKB_BASE_URL


def html_decode(value: str) -> str:
    return unescape(value or "").strip()


def strip_tags(value: str) -> str:
    without_tags = re.sub(r"<[^>]+>", "", value or "", flags=re.S)
    return " ".join(html_decode(without_tags).split())


def find_raw(html: str, pattern: str) -> str:
    match = re.search(pattern, html or "", flags=re.S)
    return match.group(1) if match else ""


def find_text(html: str, pattern: str) -> str:
    return strip_tags(find_raw(html, pattern))


def find_href(html: str, pattern: str) -> str:
    return html_decode(find_raw(html, pattern))


def absolutize(url: str) -> str:
    return urljoin(DJKB_BASE_URL, url) if url else ""
