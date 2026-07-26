import sqlite3
import time

from config import DATABASE_PATH


IGNORED_PATHS = {
    "/",
    "/admin",
    "/health",
    "/geocode/status",
    "/stats",
    "/favicon.ico",
}


def create_access_counts_table(connection):
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS access_counts (
            day TEXT NOT NULL,
            path TEXT NOT NULL,
            platform TEXT NOT NULL,
            request_count INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (day, path, platform)
        )
        """
    )
def database_connection():
    connection = sqlite3.connect(DATABASE_PATH, timeout=10)
    connection.row_factory = sqlite3.Row
    create_access_counts_table(connection)
    return connection


def should_record_request(path: str) -> bool:
    return path not in IGNORED_PATHS


def record_access(*, path: str, platform: str):
    if not should_record_request(path):
        return

    day = time.strftime("%Y-%m-%d", time.gmtime())
    with database_connection() as connection:
        connection.execute(
            """
            INSERT INTO access_counts (day, path, platform, request_count)
            VALUES (?, ?, ?, 1)
            ON CONFLICT(day, path, platform) DO UPDATE SET
                request_count = request_count + 1
            """,
            (day, path[:200], normalize_platform(platform)),
        )


def normalize_platform(platform: str) -> str:
    platform = (platform or "").strip().lower()
    if platform in {"android", "ios", "macos", "windows", "linux"}:
        return platform

    return "unknown"


def access_summary():
    today = time.strftime("%Y-%m-%d", time.gmtime())
    with database_connection() as connection:
        total_requests = connection.execute(
            "SELECT COALESCE(SUM(request_count), 0) AS count FROM access_counts"
        ).fetchone()["count"]
        today_requests = connection.execute(
            """
            SELECT COALESCE(SUM(request_count), 0) AS count
            FROM access_counts
            WHERE day = ?
            """,
            (today,),
        ).fetchone()["count"]
        by_platform = connection.execute(
            """
            SELECT platform, SUM(request_count) AS requests
            FROM access_counts
            GROUP BY platform
            ORDER BY requests DESC
            """
        ).fetchall()
        by_path = connection.execute(
            """
            SELECT path, SUM(request_count) AS count
            FROM access_counts
            GROUP BY path
            ORDER BY count DESC
            LIMIT 20
            """
        ).fetchall()

    return {
        "total_requests": total_requests,
        "today_requests": today_requests,
        "by_platform": [
            {
                "platform": row["platform"],
                "requests": row["requests"],
            }
            for row in by_platform
        ],
        "by_path": [
            {
                "path": row["path"],
                "count": row["count"],
            }
            for row in by_path
        ],
    }
