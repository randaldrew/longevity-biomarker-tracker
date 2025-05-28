#!/usr/bin/env python3
"""Generate query execution plans for performance documentation."""
import os
import json
import pymysql
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "port": int(os.getenv("MYSQL_PORT", 3307)),
    "user": os.getenv("MYSQL_USER", "biomarker_user"),
    "password": os.getenv("MYSQL_PASSWORD", "biomarker_pass"),
    "database": os.getenv("MYSQL_DATABASE", "longevity"),
    "charset": "utf8mb4",
    "cursorclass": pymysql.cursors.DictCursor,
}


def analyze_trend_query():
    """Analyze the biomarker trend query performance"""
    connection = pymysql.connect(**DB_CONFIG)

    try:
        with connection.cursor() as cursor:
            # Test the main trend query with EXPLAIN
            explain_query = """
            EXPLAIN FORMAT=JSON
            SELECT
                MeasurementSession.SessionDate AS date,
                Measurement.Value AS value,
                Measurement.SessionID AS sessionId
            FROM Measurement
            JOIN MeasurementSession ON Measurement.SessionID=MeasurementSession.SessionID
            WHERE MeasurementSession.UserID = 1
              AND Measurement.BiomarkerID = 1
              AND MeasurementSession.SessionDate > '2017-01-01'
            ORDER BY MeasurementSession.SessionDate DESC
            LIMIT 20
            """

            cursor.execute(explain_query)
            result = cursor.fetchone()

            # Save to docs for submission
            with open("docs/trend_query_performance.json", "w") as f:
                json.dump(result, f, indent=2, default=str)

            print("✓ Query plan saved to docs/trend_query_performance.json")

            # Show indexes being used
            cursor.execute("SHOW INDEX FROM Measurement")
            indexes = cursor.fetchall()
            print(f"✓ Measurement table has {len(indexes)} indexes")

    finally:
        connection.close()


if __name__ == "__main__":
    analyze_trend_query()
