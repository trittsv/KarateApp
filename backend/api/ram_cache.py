import copy
import threading
import time

from config import DATA_CACHE_TTL_SECONDS
from geocoding import cached_geocode_location


LOCK = threading.Lock()
CACHES = {
    "appointments": {
        "items": None,
        "loaded_at": 0.0,
    },
    "dojos": {
        "items": None,
        "loaded_at": 0.0,
    },
}


def is_fresh(entry: dict) -> bool:
    return entry["items"] is not None and time.monotonic() - entry["loaded_at"] < DATA_CACHE_TTL_SECONDS


def get_cached(name: str):
    with LOCK:
        entry = CACHES[name]
        if not is_fresh(entry):
            entry["items"] = None
            entry["loaded_at"] = 0.0
            return None

        return copy.deepcopy(entry["items"])


def set_cached(name: str, items: list[dict]):
    with LOCK:
        CACHES[name]["items"] = copy.deepcopy(items)
        CACHES[name]["loaded_at"] = time.monotonic()


def enrich_appointment_coordinates(items: list[dict]) -> list[dict]:
    for item in items:
        location = item.get("location") or {}
        if location.get("has_coordinate"):
            continue
        cached_geocode_location(location)
        item["location"] = location
    return items


def enrich_dojo_coordinates(items: list[dict]) -> list[dict]:
    for item in items:
        if item.get("has_coordinate"):
            continue

        location = {
            "street": item.get("street", ""),
            "zip": "",
            "city": item.get("zip_city", ""),
        }
        cached_geocode_location(location)
        item["latitude"] = location.get("latitude")
        item["longitude"] = location.get("longitude")
        item["has_coordinate"] = location["has_coordinate"]
    return items


def cached_or_load(name: str, loader, enricher):
    cached_items = get_cached(name)
    if cached_items is not None:
        return enricher(cached_items), True

    items = enricher(loader())
    set_cached(name, items)
    return copy.deepcopy(items), False
