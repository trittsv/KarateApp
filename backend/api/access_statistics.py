import sqlite3
import time

from config import DATABASE_PATH


IGNORED_PATHS = {
    "/",
    "/admin",
    "/health",
    "/geocode/status",
    "/stats",
    "/favicon.ico"
}


def create_access_log_table(connection):
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS access_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at INTEGER NOT NULL,
            path TEXT NOT NULL,
            platform TEXT NOT NULL DEFAULT '',
            client_id TEXT NOT NULL DEFAULT ''
        )
        """
    )


def access_log_columns(connection):
    return {
        row["name"]
        for row in connection.execute("PRAGMA table_info(access_log)").fetchall()
    }


def migrate_access_log_if_needed(connection):
    columns = access_log_columns(connection)
    obsolete_columns = {
        "method",
        "endpoint",
        "status_code",
        "duration_ms",
        "user_agent",
    }
    if not obsolete_columns.intersection(columns):
        return

    connection.execute(
        """
        CREATE TABLE access_log_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at INTEGER NOT NULL,
            path TEXT NOT NULL,
            platform TEXT NOT NULL DEFAULT '',
            client_id TEXT NOT NULL DEFAULT ''
        )
        """
    )
    connection.execute(
        """
        INSERT INTO access_log_new (id, created_at, path, platform, client_id)
        SELECT id, created_at, path, platform, client_id
        FROM access_log
        """
    )
    connection.execute("DROP TABLE access_log")
    connection.execute("ALTER TABLE access_log_new RENAME TO access_log")


def database_connection():
    connection = sqlite3.connect(DATABASE_PATH, timeout=10)
    connection.row_factory = sqlite3.Row
    create_access_log_table(connection)
    migrate_access_log_if_needed(connection)
    columns = {
        row["name"]
        for row in connection.execute("PRAGMA table_info(access_log)").fetchall()
    }
    if "platform" not in columns:
        connection.execute(
            "ALTER TABLE access_log ADD COLUMN platform TEXT NOT NULL DEFAULT ''"
        )
    if "client_id" not in columns:
        connection.execute(
            "ALTER TABLE access_log ADD COLUMN client_id TEXT NOT NULL DEFAULT ''"
        )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_access_log_created_at
        ON access_log(created_at)
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_access_log_path
        ON access_log(path)
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_access_log_client_id
        ON access_log(client_id)
        """
    )
    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_access_log_platform
        ON access_log(platform)
        """
    )
    return connection


def should_record_request(path: str) -> bool:
    return path not in IGNORED_PATHS


def record_access(
    *,
    path: str,
    platform: str,
    client_id: str,
):
    if not should_record_request(path):
        return

    with database_connection() as connection:
        connection.execute(
            """
            INSERT INTO access_log (
                created_at,
                path,
                platform,
                client_id
            )
            VALUES (?, ?, ?, ?)
            """,
            (
                int(time.time()),
                path[:200],
                normalize_platform(platform),
                client_id[:120],
            ),
        )


def normalize_platform(platform: str) -> str:
    platform = (platform or "").strip().lower()
    if platform in {"android", "ios", "macos", "windows", "linux"}:
        return platform

    return "unknown"


def access_summary():
    with database_connection() as connection:
        total_requests = connection.execute(
            "SELECT COUNT(*) AS count FROM access_log"
        ).fetchone()["count"]
        total_users = connection.execute(
            """
            SELECT COUNT(DISTINCT client_id) AS count
            FROM access_log
            WHERE client_id != ''
            """
        ).fetchone()["count"]
        last_24h_requests = connection.execute(
            """
            SELECT COUNT(*) AS count
            FROM access_log
            WHERE created_at >= ?
            """,
            (int(time.time()) - 24 * 60 * 60,),
        ).fetchone()["count"]
        last_24h_users = connection.execute(
            """
            SELECT COUNT(DISTINCT client_id) AS count
            FROM access_log
            WHERE created_at >= ? AND client_id != ''
            """,
            (int(time.time()) - 24 * 60 * 60,),
        ).fetchone()["count"]
        by_platform = connection.execute(
            """
            SELECT
                COALESCE(NULLIF(platform, ''), 'unknown') AS platform_name,
                COUNT(*) AS requests,
                COUNT(DISTINCT NULLIF(client_id, '')) AS users
            FROM access_log
            GROUP BY platform_name
            ORDER BY requests DESC
            """
        ).fetchall()
        by_path = connection.execute(
            """
            SELECT path, COUNT(*) AS count
            FROM access_log
            GROUP BY path
            ORDER BY count DESC
            LIMIT 20
            """
        ).fetchall()

    return {
        "total_requests": total_requests,
        "total_users": total_users,
        "last_24h_requests": last_24h_requests,
        "last_24h_users": last_24h_users,
        "by_platform": [
            {
                "platform": row["platform_name"],
                "requests": row["requests"],
                "users": row["users"],
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
