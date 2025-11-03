#!/usr/bin/env python3
import json
import os
import time
import psycopg2
import psycopg2.extras

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

def get_random_empty_hex(conn):
    """
    Selects a random hex from the pre-calculated candidates table and fetches its geometry.
    """
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("""
            SELECT 
                ix,
                ST_AsGeoJSON(ST_Transform(geom, 4326)) AS hex_geometry,
                ST_AsGeoJSON(ST_Transform(ST_Centroid(geom), 4326)) as hex_center
                FROM h3.no_landcover 
  	            ORDER BY RANDOM() 
	            LIMIT 1;
        """)
        return cur.fetchone()

def get_hex_stats(conn, hex_id):
    """
    Calculates the landcover statistics for a given hexagon ID.
    """
    if not hex_id:
        return []
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("""
            SELECT
                feature,
                SUM(ST_Area(clipped_geom)) AS area,
                (SUM(ST_Area(clipped_geom)) / (SELECT ST_Area(geom) FROM h3.hex WHERE ix = %(hex_id)s)) * 100 AS percentage
            FROM h3.landcovers_clipped
            WHERE ix = %(hex_id)s
            GROUP BY feature
            ORDER BY percentage DESC;
        """, {'hex_id': hex_id})
        stats = cur.fetchall()
        return [dict(row) for row in stats]

def main():
    """
    Main CGI script execution.
    """
    print("Content-Type: application/json")
    print() # Important: blank line separating headers from body

    conn = get_db_connection()
    if not conn:
        print(json.dumps({"error": "Database connection failed"}))
        return

    output_data = {}
    start_time = time.perf_counter()
    try:
        empty_hex = get_random_empty_hex(conn)
        get_random_empty_hex_time = time.perf_counter() - start_time
        if not empty_hex:
            output_data = {"error": "No empty hexes found that meet the criteria."}
        else:
            start_time = time.perf_counter()
            stats = get_hex_stats(conn, empty_hex['ix'])
            get_hex_stats_time = time.perf_counter() - start_time
            output_data = {
                "hex_id": empty_hex['ix'],
                "geometry": json.loads(empty_hex['hex_geometry']),
                "center": json.loads(empty_hex['hex_center']),
                "stats": stats,
                "profiling": {
                    "get_random_empty_hex_seconds": round(get_random_empty_hex_time, 3),
                    "get_hex_stats_seconds": round(get_hex_stats_time, 3)
                    }}
    except psycopg2.Error as e:
        output_data = {"error": "A database error occurred.", "details": str(e)}
    finally:
        if conn:
            conn.close()

    print(json.dumps(output_data, indent=2))

if __name__ == "__main__":
    main()
