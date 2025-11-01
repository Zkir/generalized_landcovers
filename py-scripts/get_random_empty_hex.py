
import psycopg2
import psycopg2.extras
import json
import os

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
    except psycopg2.OperationalError as e:
        print(f"Error: Could not connect to the database. Please check your connection settings.\n{e}")
        return None

def get_random_empty_hex(conn):
    """
    Finds a random H3 hexagon that has landcover features but doesn't appear in the final aggregated map.
    """
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        # Find a random hex from the hex grid that is NOT in the final output.
        # This is our "empty" hex. We also grab its geometry and center.
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
            LIMIT 1;
        """)
        empty_hex = cur.fetchone()
        return empty_hex

def get_hex_stats(conn, hex_id):
    """
    Calculates the landcover statistics for a given hexagon ID directly from the clipped data.
    """
    if not hex_id:
        return []

    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        # Re-calculate stats for the given hex from the clipped data,
        # as the intermediate stats table gets pruned during the build process.
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
    Main function to get data for a random empty hex and write it to a JSON file.
    """
    conn = get_db_connection()
    if not conn:
        return

    print("Searching for a random empty hex...")
    empty_hex = get_random_empty_hex(conn)

    if not empty_hex:
        print("Could not find any empty hexes. The map might be fully covered.")
        output_data = {"error": "No empty hexes found."}
    else:
        print(f"Found empty hex: {empty_hex['ix']}. Fetching stats...")
        stats = get_hex_stats(conn, empty_hex['ix'])
        print("Stats fetched.")

        output_data = {
            "hex_id": empty_hex['ix'],
            "geometry": json.loads(empty_hex['hex_geometry']),
            "center": json.loads(empty_hex['hex_center']),
            "stats": stats
        }

    conn.close()

    output_path = os.path.join(os.path.dirname(__file__), '../webui-prototypes/empty_hex_data.json')
    print(f"Writing data to {output_path}...")
    with open(output_path, 'w') as f:
        json.dump(output_data, f, indent=2)
    print("Done.")

if __name__ == "__main__":
    main()
