import logging
import sqlite3
import threading
import time

import requests

from config import (
    DATABASE_PATH,
    LOCATIONIQ_API_KEY,
    LOCATIONIQ_ENDPOINT,
    LOCATIONIQ_MIN_INTERVAL_SECONDS,
    REQUEST_TIMEOUT_SECONDS,
)


NO_RESULT_STATUS_CODES = {400, 404}
IN_FLIGHT_LOCKS = {}
IN_FLIGHT_LOCKS_LOCK = threading.Lock()
LOCATIONIQ_RATE_LOCK = threading.Lock()
LAST_LOCATIONIQ_REQUEST_AT = 0.0
GEOCODING_STATUS_LOCK = threading.Lock()
ACTIVE_LOCATIONIQ_REQUESTS = 0
WAITING_LOCATIONIQ_REQUESTS = 0
CURRENT_LOCATIONIQ_QUERY = ""
LAST_LOCATIONIQ_STARTED_AT = 0
LAST_LOCATIONIQ_FINISHED_AT = 0
CLEANED_DATA_CACHE_TABLES = False


def normalize_query(query: str) -> str:
    return " ".join((query or "").lower().split())


def database_connection():
    global CLEANED_DATA_CACHE_TABLES

    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    if not CLEANED_DATA_CACHE_TABLES:
        connection.execute("DROP TABLE IF EXISTS appointment_cache")
        connection.execute("DROP TABLE IF EXISTS dojo_cache")
        CLEANED_DATA_CACHE_TABLES = True
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS geocode_cache (
            normalized_query TEXT PRIMARY KEY,
            original_query TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            display_name TEXT,
            found INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        )
        """
    )
    return connection


def cached_result(normalized_query: str):
    with database_connection() as connection:
        row = connection.execute(
            "SELECT * FROM geocode_cache WHERE normalized_query = ?",
            (normalized_query,),
        ).fetchone()

    if row is None:
        return None

    return {
        "query": row["original_query"],
        "normalized_query": row["normalized_query"],
        "found": bool(row["found"]),
        "latitude": row["latitude"],
        "longitude": row["longitude"],
        "display_name": row["display_name"] or "",
        "cached": True,
    }


def save_result(
    *,
    query: str,
    normalized_query: str,
    found: bool,
    latitude=None,
    longitude=None,
    display_name: str = "",
):
    now = int(time.time())
    with database_connection() as connection:
        connection.execute(
            """
            INSERT INTO geocode_cache (
                normalized_query,
                original_query,
                latitude,
                longitude,
                display_name,
                found,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(normalized_query) DO UPDATE SET
                original_query = excluded.original_query,
                latitude = excluded.latitude,
                longitude = excluded.longitude,
                display_name = excluded.display_name,
                found = excluded.found,
                updated_at = excluded.updated_at
            """,
            (
                normalized_query,
                query,
                latitude,
                longitude,
                display_name,
                1 if found else 0,
                now,
                now,
            ),
        )


def clear_geocode_cache() -> int:
    with database_connection() as connection:
        cursor = connection.execute("DELETE FROM geocode_cache")
        return cursor.rowcount


def query_lock(normalized_query: str):
    with IN_FLIGHT_LOCKS_LOCK:
        lock = IN_FLIGHT_LOCKS.get(normalized_query)
        if lock is None:
            lock = threading.Lock()
            IN_FLIGHT_LOCKS[normalized_query] = lock
        return lock


def geocoding_status():
    with GEOCODING_STATUS_LOCK:
        return {
            "geocoding": ACTIVE_LOCATIONIQ_REQUESTS > 0,
            "waiting": WAITING_LOCATIONIQ_REQUESTS > 0,
            "active_requests": ACTIVE_LOCATIONIQ_REQUESTS,
            "waiting_requests": WAITING_LOCATIONIQ_REQUESTS,
            "current_query": CURRENT_LOCATIONIQ_QUERY,
            "last_started_at": LAST_LOCATIONIQ_STARTED_AT,
            "last_finished_at": LAST_LOCATIONIQ_FINISHED_AT,
        }


def locationiq_lookup(query: str):
    global ACTIVE_LOCATIONIQ_REQUESTS
    global CURRENT_LOCATIONIQ_QUERY
    global LAST_LOCATIONIQ_FINISHED_AT
    global LAST_LOCATIONIQ_REQUEST_AT
    global LAST_LOCATIONIQ_STARTED_AT
    global WAITING_LOCATIONIQ_REQUESTS

    if not LOCATIONIQ_API_KEY:
        return {"error": "LOCATIONIQ_API_KEY is not configured"}, 500

    with GEOCODING_STATUS_LOCK:
        WAITING_LOCATIONIQ_REQUESTS += 1

    with LOCATIONIQ_RATE_LOCK:
        with GEOCODING_STATUS_LOCK:
            WAITING_LOCATIONIQ_REQUESTS -= 1
            ACTIVE_LOCATIONIQ_REQUESTS += 1
            CURRENT_LOCATIONIQ_QUERY = query
            LAST_LOCATIONIQ_STARTED_AT = int(time.time())

        try:
            now = time.monotonic()
            wait_seconds = LOCATIONIQ_MIN_INTERVAL_SECONDS - (now - LAST_LOCATIONIQ_REQUEST_AT)
            if wait_seconds > 0:
                time.sleep(wait_seconds)
            LAST_LOCATIONIQ_REQUEST_AT = time.monotonic()

            response = requests.get(
                LOCATIONIQ_ENDPOINT,
                params={
                    "key": LOCATIONIQ_API_KEY,
                    "q": query,
                    "format": "json",
                    "limit": 1,
                    "accept-language": "de",
                    "addressdetails": 0,
                },
                timeout=REQUEST_TIMEOUT_SECONDS,
                headers={
                    "User-Agent": "KarateAppGeocoder/1.0",
                },
            )
        finally:
            with GEOCODING_STATUS_LOCK:
                ACTIVE_LOCATIONIQ_REQUESTS -= 1
                CURRENT_LOCATIONIQ_QUERY = ""
                LAST_LOCATIONIQ_FINISHED_AT = int(time.time())

    if response.status_code in NO_RESULT_STATUS_CODES:
        return {
            "found": False,
            "latitude": None,
            "longitude": None,
            "display_name": "",
        }, 200

    if response.status_code != 200:
        return {
            "error": "locationiq_request_failed",
            "status_code": response.status_code,
            "response": response.text[:500],
        }, 502

    data = response.json()
    if not data:
        return {
            "found": False,
            "latitude": None,
            "longitude": None,
            "display_name": "",
        }, 200

    first = data[0]
    return {
        "found": True,
        "latitude": float(first["lat"]),
        "longitude": float(first["lon"]),
        "display_name": first.get("display_name", ""),
    }, 200


def geocode_query(query: str):
    query = (query or "").strip()
    normalized_query = normalize_query(query)
    if not normalized_query:
        return None

    cached = cached_result(normalized_query)
    if cached is not None:
        return cached if cached["found"] else None

    lock = query_lock(normalized_query)
    with lock:
        cached = cached_result(normalized_query)
        if cached is not None:
            return cached if cached["found"] else None

        result, status_code = locationiq_lookup(query)
        if status_code != 200:
            logging.warning("geocode failed for %s: %s", query, result)
            return None

        save_result(
            query=query,
            normalized_query=normalized_query,
            found=result["found"],
            latitude=result["latitude"],
            longitude=result["longitude"],
            display_name=result["display_name"],
        )
        return result if result["found"] else None


def cached_geocode_query(query: str):
    query = (query or "").strip()
    normalized_query = normalize_query(query)
    if not normalized_query:
        return None

    cached = cached_result(normalized_query)
    return cached if cached is not None and cached["found"] else None


def build_location_queries(location: dict):
    parts = []
    street = (location.get("street") or "").strip()
    zip_city = " ".join(
        value for value in [
            (location.get("zip") or "").strip(),
            (location.get("city") or "").strip(),
        ]
        if value
    )
    if street:
        parts.append(street)
    if zip_city:
        parts.append(zip_city)

    query = ", ".join(parts)
    queries = []
    if query:
        queries.append(query)
    if zip_city and query != zip_city:
        queries.append(zip_city)
    return queries


def cached_geocode_location(location: dict):
    result = None
    for query in build_location_queries(location):
        result = cached_geocode_query(query)
        if result is not None:
            break

    if result is None:
        location["has_coordinate"] = False
        return location

    location["latitude"] = result["latitude"]
    location["longitude"] = result["longitude"]
    location["has_coordinate"] = True
    return location


def geocode_location(location: dict):
    result = None
    for query in build_location_queries(location):
        result = geocode_query(query)
        if result is not None:
            break

    if result is None:
        location["has_coordinate"] = False
        return location

    location["latitude"] = result["latitude"]
    location["longitude"] = result["longitude"]
    location["has_coordinate"] = True
    return location
