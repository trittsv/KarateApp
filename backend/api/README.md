# Karate App Backend

Small Flask backend for DJKB parsing and geocoding. The mobile/desktop app asks
this service for parsed JSON; only the backend talks to the DJKB website and
LocationIQ.

The root page (`GET /`) shows the public Karate App download page. The admin
page (`GET /admin`) shows a small backend dashboard with geocoding status,
request counts, approximate users, and platform split.

## Endpoints

```text
GET /health
GET /admin
GET /stats
GET /geocode?q=74321 Bietigheim-Bissingen
GET /geocode/status
GET /appointments
GET /dojos
GET /news?section=news
GET /news?section=results
GET /news/detail?url=https://www.djkb.com/...
GET /gallery/years
GET /gallery/albums?url=https://www.djkb.com/bilder/2026/
GET /gallery/photos?url=https://www.djkb.com/...
```

App requests send these privacy-friendly headers so the backend can count
approximate users and platforms:

```text
X-KarateApp-Client-Id: random app installation UUID
X-KarateApp-Platform: ios | android | macos | windows | linux
```

## Files

```text
app.py               Flask routes and response handling
config.py            Environment/config constants
geocoding.py         LocationIQ access, SQLite cache, request throttling
ram_cache.py         Short-lived in-memory appointment and dojo cache
access_statistics.py Privacy-friendly access statistics in SQLite
html_utils.py        Shared HTML parsing helpers
djkb_appointments.py Appointment scraping and coordinate enrichment
djkb_dojos.py        Dojo scraping and coordinate enrichment
djkb_news.py         News and result scraping
djkb_gallery.py      Gallery years, albums, and photos
```

Example response:

```json
{
  "found": true,
  "latitude": 48.9607,
  "longitude": 9.1339,
  "display_name": "...",
  "cached": false
}
```

## Local Run

```bash
cd backend/api
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
export LOCATIONIQ_API_KEY="your-locationiq-key"
flask --app app:APP run
```

## Render

Create a new Render Web Service from this repo. Use:

```text
Root Directory: backend/api
Build Command: pip install -r requirements.txt
Start Command: gunicorn app:APP
```

For in-flight request deduplication, prefer one worker with a small number of threads:

```text
gunicorn --workers 1 --threads 2 app:APP
```

The backend uses a per-query in-memory lock. With multiple workers each process
has its own lock map, so simultaneous requests could still duplicate across
workers.

LocationIQ calls are additionally rate-limited inside the backend to at most one
request every 1.3 seconds. Cached results return immediately.

The SQLite database stores:

```text
geocode_cache      normalized location -> latitude/longitude
access_log         privacy-friendly backend usage counters
```

Appointments and dojos are cached only in RAM for
`KARATEAPP_DATA_CACHE_TTL_SECONDS` (default: 600 seconds). Clients do not store
appointments or geocode results locally. They load appointments/dojos from the
backend and request missing coordinates one by one via `/geocode`; the backend
fills `geocode_cache`, and future appointment/dojo JSON responses include the
coordinates from SQLite when available.

Environment variables:

```text
LOCATIONIQ_API_KEY=your-locationiq-key
KARATEAPP_BACKEND_DATABASE=/var/data/geocode_cache.sqlite3
KARATEAPP_DATA_CACHE_TTL_SECONDS=600
```

Add a persistent disk mounted at:

```text
/var/data
```

Without a persistent disk the cache still works, but it is reset whenever Render
restarts the service.
