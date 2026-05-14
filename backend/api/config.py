import os
from pathlib import Path


LOCATIONIQ_API_KEY = os.environ.get("LOCATIONIQ_API_KEY", "")
LOCATIONIQ_ENDPOINT = "https://eu1.locationiq.com/v1/search"
LOCATIONIQ_MIN_INTERVAL_SECONDS = 1.3
ADMIN_USERNAME = os.environ.get("KARATEAPP_ADMIN_USERNAME", "")
ADMIN_PASSWORD = os.environ.get("KARATEAPP_ADMIN_PASSWORD", "")

DATABASE_PATH = Path(
    os.environ.get("KARATEAPP_BACKEND_DATABASE", "geocode_cache.sqlite3")
)
REQUEST_TIMEOUT_SECONDS = 20
DATA_CACHE_TTL_SECONDS = int(os.environ.get("KARATEAPP_DATA_CACHE_TTL_SECONDS", "600"))

DJKB_BASE_URL = "https://www.djkb.com"
DJKB_HEADERS = {
    "User-Agent": "Mozilla/5.0",
    "Accept": "text/html, */*; q=0.01",
}
