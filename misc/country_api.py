#!/usr/bin/env python3
import json
import os
import cgi
import sqlite3
from decimal import Decimal

SQLITE_DB_PATH = 'landcover_stats.sqlite'

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_db_connection():
    """Establishes a connection to the SQLite database."""
    try:
        conn = sqlite3.connect(SQLITE_DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error:
        return None

def get_stats(conn, country=None):
    """Fetches pre-computed statistics from the country_stats table."""
    with conn:
        cur = conn.cursor()
        if country:
            if country == 'All Countries':
                cur.execute("""
                    SELECT
                        'All Countries' as name_en,
                        SUM(total_hexes) as total_hexes,
                        SUM(empty_hexes) as empty_hexes,
                        SUM(pcover * total_hexes) / SUM(total_hexes) as pcover
                    FROM country_stats
                    WHERE total_hexes > 0;
                """)
            else:
                cur.execute("SELECT * FROM country_stats WHERE name_en = ?", (country,))
            result = cur.fetchone()
            return dict(result) if result else {}
        else:
            cur.execute("SELECT * FROM country_stats ORDER BY name_en ASC;")
            results = cur.fetchall()
            return [dict(row) for row in results]

def main():
    """Main CGI script execution."""
    print("Content-Type: application/json")
    print()

    conn = get_db_connection()
    if not conn:
        print(json.dumps({"error": "Database connection failed"}))
        return

    form = cgi.FieldStorage()
    country = form.getvalue('country') or None

    try:
        stats = get_stats(conn, country)
        print(json.dumps(stats, indent=2, cls=DecimalEncoder))
    except (sqlite3.Error, KeyError) as e:
        print(json.dumps({"error": "A database error occurred or data not found.", "details": str(e)}))
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
