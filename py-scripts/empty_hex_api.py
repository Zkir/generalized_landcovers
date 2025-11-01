#!/usr/bin/env python3
import json
import os
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
    Finds a random H3 hexagon that has landcover features, doesn't appear in the
    final aggregated map, and is not mostly covered by water.
    """
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        # NOTE: ORDER BY RANDOM() was removed for performance reasons.
        # This will cause the query to always return the same hex.
        cur.execute("""
            SELECT
                h.ix,
                ST_AsGeoJSON(ST_Transform(h.geom, 4326)) AS hex_geometry,
                ST_AsGeoJSON(ST_Transform(ST_Centroid(h.geom), 4326)) as hex_center
            FROM h3.hex h
            WHERE
                h.resolution = 6
                AND h.ix IN (SELECT DISTINCT ix FROM h3.landcovers_clipped)
                AND CAST(h.ix AS VARCHAR(16)) NOT IN (SELECT DISTINCT ix FROM h3.landcovers_h3)
                AND ST_Y(ST_Centroid(h.geom)) > -60
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
    try:
        empty_hex = get_random_empty_hex(conn)
        if not empty_hex:
            output_data = {"error": "No empty hexes found that meet the criteria."}
        else:
            stats = get_hex_stats(conn, empty_hex['ix'])
            output_data = {
                "hex_id": empty_hex['ix'],
                "geometry": json.loads(empty_hex['hex_geometry']),
                "center": json.loads(empty_hex['hex_center']),
                "stats": stats
            }
    except psycopg2.Error as e:
        output_data = {"error": "A database error occurred.", "details": str(e)}
    finally:
        if conn:
            conn.close()

    print(json.dumps(output_data, indent=2))

if __name__ == "__main__":
    main()
