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

def get_countries(conn):
    """Fetches a list of country names from the database."""
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute("SELECT name_en FROM h3.country_polygons ORDER BY name_en ASC;")
        # The query assumes a 'name' column in a 'h3.country_list' table.
        # This might need adjustment based on the actual database schema.
        countries = [row['name_en'] for row in cur.fetchall()]
        return countries

def main():
    """
    Main CGI script execution to output a JSON list of countries.
    """
    print("Content-Type: application/json")
    print() # Important: blank line separating headers from body

    conn = get_db_connection()
    if not conn:
        print(json.dumps({"error": "Database connection failed"}))
        return

    output_data = []
    try:
        output_data = get_countries(conn)
    except psycopg2.Error as e:
        # If the table doesn't exist, we might need to fall back
        # to another source or provide a more specific error.
        output_data = {"error": "A database error occurred.", "details": str(e)}
    finally:
        if conn:
            conn.close()

    print(json.dumps(output_data, indent=2))

if __name__ == "__main__":
    main()
