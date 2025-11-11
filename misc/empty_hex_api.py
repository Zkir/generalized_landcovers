#!/usr/bin/env python3
import json
import os
import time
import sqlite3
import cgi

SQLITE_DB_PATH = 'landcover_stats.sqlite'

def get_sqlite_connection():
    """Establishes a connection to the SQLite database."""
    try:
        conn = sqlite3.connect(SQLITE_DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error:
        return None

def get_random_empty_hex(conn, country=None):
    """
    Selects a random hex with its geometry and center from the SQLite database,
    optionally filtered by country.
    """
    with conn:
        cur = conn.cursor()
        sql_query = "SELECT ix, hex_geometry, hex_center FROM no_landcover_per_country"
        params = []
        if country:
            sql_query += " WHERE country_name = ?"
            params.append(country)

        sql_query += " ORDER BY RANDOM() LIMIT 1;"
        cur.execute(sql_query, params)
        row = cur.fetchone()
        return dict(row) if row else None

def get_hex_stats(conn, hex_id):
    """
    Calculates the landcover statistics for a given hexagon ID from SQLite.
    """
    if not hex_id:
        return []
    with conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT
                feature,
                area,
                percentage
            FROM hex_features_stats
            WHERE ix = ?
            ORDER BY percentage DESC;
        """, (hex_id,))
        stats = cur.fetchall()
        return [dict(row) for row in stats]

def main():
    """
    Main CGI script execution.
    """
    print("Content-Type: application/json")
    print() # Important: blank line separating headers from body

    sqlite_conn = get_sqlite_connection()
    if not sqlite_conn:
        print(json.dumps({"error": "SQLite database connection failed"}))
        return

    output_data = {}
    start_time = time.perf_counter()

    # Parse query parameters
    form = cgi.FieldStorage()
    country = form.getvalue('country')

    try:
        # 1. Get a random hex ID and its geometry from SQLite
        empty_hex = get_random_empty_hex(sqlite_conn, country)
        get_random_empty_hex_time = time.perf_counter() - start_time

        if not empty_hex:
            output_data = {"error": "No empty hexes found that meet the criteria."}
        else:
            # 2. Get detailed stats from SQLite
            start_time_sqlite_stats = time.perf_counter()
            stats = get_hex_stats(sqlite_conn, empty_hex['ix'])
            get_hex_stats_time = time.perf_counter() - start_time_sqlite_stats

            output_data = {
                "hex_id": empty_hex['ix'],
                "geometry": json.loads(empty_hex['hex_geometry']),
                "center": json.loads(empty_hex['hex_center']),
                "stats": stats,
                "profiling": {
                    "get_random_empty_hex_seconds": round(get_random_empty_hex_time, 3),
                    "get_hex_stats_seconds": round(get_hex_stats_time, 3)
                }
            }
    except (sqlite3.Error, KeyError) as e:
        output_data = {"error": "A database error occurred.", "details": str(e)}
    finally:
        if sqlite_conn:
            sqlite_conn.close()

    print(json.dumps(output_data, indent=2))

if __name__ == "__main__":
    main()
