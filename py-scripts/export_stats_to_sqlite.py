
import os
import psycopg2
import sqlite3

# --- Configuration ---
PG_DBNAME = 'gis'
PG_USER = os.environ.get("PGUSER")
PG_PASSWORD = os.environ.get("PGPASSWORD")
SQLITE_DB_PATH = 'data/export/landcover_stats.sqlite'

TABLES_TO_EXPORT = {
    'no_landcover_per_country': """
        SELECT
            ix,
            ST_AsGeoJSON(ST_Transform(geom, 4326)) AS hex_geometry,
            ST_AsGeoJSON(ST_Transform(ST_Centroid(geom), 4326)) as hex_center,
            country_name
        FROM h3.no_landcover_per_country
    """,
    'country_stats': """
		SELECT 
			name_en,
			total_hexes,
			empty_hexes,
			pcover
		FROM h3.country_stats
	""",
    'hex_features_stats': """
        SELECT
            ix,
            feature,
            srid_area AS area,
            area_rate*100 AS percentage 
        FROM h3.hex_features_stats2
    """    
}

# --- Pre-check ---
if not all([PG_USER, PG_PASSWORD]):
    print('Error: PGUSER and PGPASSWORD environment variables must be set.')
    exit(1)

# --- Main Logic ---
def export_data():
    """
    Connects to PostgreSQL, fetches data from specified tables,
    and writes it to a new SQLite database.
    """
    print(f"Starting export to SQLite database: {SQLITE_DB_PATH}")

    # Connect to PostgreSQL
    try:
        pg_conn = psycopg2.connect(
            dbname=PG_DBNAME,
            user=PG_USER,
            password=PG_PASSWORD,
            host='localhost'
        )
        pg_cursor = pg_conn.cursor()
        print("Successfully connected to PostgreSQL.")
    except psycopg2.OperationalError as e:
        print(f"Error connecting to PostgreSQL: {e}")
        exit(1)

    # Create or connect to SQLite database
    if os.path.exists(SQLITE_DB_PATH):
        os.remove(SQLITE_DB_PATH)
        print(f"Removed existing SQLite database: {SQLITE_DB_PATH}")
        
    sqlite_conn = sqlite3.connect(SQLITE_DB_PATH)
    sqlite_cursor = sqlite_conn.cursor()
    print(f"Created new SQLite database: {SQLITE_DB_PATH}")

    # Process each table
    for table_name, select_query in TABLES_TO_EXPORT.items():
        print(f"Processing table: {table_name}...")

        # Fetch data from PostgreSQL
        try:
            pg_cursor.execute(select_query)
            rows = pg_cursor.fetchall()
            column_names = [desc[0] for desc in pg_cursor.description]
            print(f"  Fetched {len(rows)} rows from h3.{table_name}.")
        except psycopg2.Error as e:
            print(f"  Error fetching data for {table_name}: {e}")
            continue

        if not rows:
            print(f"  No data found for {table_name}, skipping.")
            continue

        # Create table in SQLite
        create_table_sql = f"CREATE TABLE {table_name} ({', '.join(column_names)})"
        sqlite_cursor.execute(create_table_sql)
        print(f"  Created SQLite table: {table_name}.")

        # Insert data into SQLite
        placeholders = ', '.join(['?'] * len(column_names))
        insert_sql = f"INSERT INTO {table_name} VALUES ({placeholders})"
        sqlite_cursor.executemany(insert_sql, rows)
        print(f"  Inserted {len(rows)} rows into SQLite table.")

    # Clean up
    sqlite_conn.commit()
    sqlite_conn.close()
    pg_conn.close()
    print("Export complete. Connections closed.")

if __name__ == "__main__":
    # Ensure the export directory exists
    os.makedirs(os.path.dirname(SQLITE_DB_PATH), exist_ok=True)
    export_data()
