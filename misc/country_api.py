#!/usr/bin/env python3
import json
import os
import cgi
import psycopg2
import psycopg2.extras
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_db_connection():
    """Establishes a connection to the PostgreSQL database."""
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("PGDATABASE", "gis"),
            user=os.getenv("PGUSER", "gis"),
            password=os.getenv("PGPASSWORD", "gis"),
            host=os.getenv("PGHOST", "localhost"),
            port=os.getenv("PGPORT", "5432")
        )
        return conn
    except psycopg2.OperationalError:
        return None

def get_stats(conn, country=None):
    """Fetches pre-computed statistics from the h3.country_stats table."""
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        if country:
            if country == 'All Countries':
                cur.execute("""
                    SELECT
                        'All Countries' as name_en,
                        SUM(total_hexes) as total_hexes,
                        SUM(empty_hexes) as empty_hexes,
                        SUM(pcover * total_hexes) / SUM(total_hexes) as pcover
                    FROM h3.country_stats
                    WHERE total_hexes > 0;
                """)
            else:
                cur.execute("SELECT * FROM h3.country_stats WHERE name_en = %(country)s", {'country': country})
            result = cur.fetchone()
            return dict(result) if result else {}
        else:
            cur.execute("SELECT * FROM h3.country_stats ORDER BY name_en ASC;")
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
    except (psycopg2.Error, KeyError) as e:
        print(json.dumps({"error": "A database error occurred or data not found.", "details": str(e)}))
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
