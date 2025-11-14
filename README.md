# OpenLandcoverMap

**OpenLandcoverMap** is a project designed to create generalized landcover maps from OpenStreetMap (OSM) data, specifically for zoom levels z0-z8. It addresses the common issue of standard OSM maps appearing empty and devoid of features at these lower zoom levels by providing a more visually informative and richer map rendering.

![Generalized Landcovers vs. Standard OSM](pic01_landcovers_vs_mapnik.png)

The live map is accessible at: **https://openlandcovermap.org**

## The Approach

The core idea of this project is to use a hexagonal grid system (Uber's H3) to process and generalize raw OSM data. For each cell in the grid, the dominant landcover type is identified, and these cells are then merged to create larger, more coherent polygons that are suitable for rendering at low zoom levels. This same principle is applied to generalize other features like cities and mountain peaks.

For a detailed explanation of the various generalization techniques used for landcovers, water bodies, populated places, and mountain peaks, please see the **[About Page](webui-prototypes/about.html)**.

## Technology Stack

This project is built upon a foundation of powerful open-source geospatial tools:

*   **PostGIS:** A PostgreSQL extension for storing and processing complex spatial data.
*   **H3:** A hexagonal hierarchical spatial index used for the core generalization logic. The `h3-pg` extension provides the necessary database functions.
*   **osm2pgsql:** For importing raw OpenStreetMap data into the PostGIS database.
*   **Mapnik:** The toolkit used for rendering the final map tiles.
*   **Python:** For various automation scripts, data analysis, and helper tasks.
*   **Make:** For orchestrating the entire data processing and build pipeline.

## Getting Started

Follow these steps to set up the project and generate the map data on your own machine.

### 1. Prerequisites

**a) OSM Data in PostGIS:**
You must have a PostGIS database (e.g., named `gis`) with OpenStreetMap data imported via `osm2pgsql`. The import command should be configured to use the `hstore` format and apply the appropriate style transformations.

A typical `osm2pgsql` command might look like this (adapt paths and parameters for your system):
```sh
osm2pgsql -d gis -U <your_user> -W --create --slim -G --hstore --tag-transform-script openstreetmap-carto.lua -C 24000 --flat-nodes /path/to/nodes.bin --number-processes 8 -S openstreetmap-carto.style /path/to/planet-latest.osm.pbf
```
For guidance on setting up a tile server, refer to tutorials like those on [switch2osm.org](https://switch2osm.org/serving-tiles/manually-building-a-tile-server-ubuntu-22-04-lts/).

**b) H3 PostGIS Extension:**
The `h3-pg` extension must be installed and enabled in your database.

On Debian/Ubuntu, you may be able to install it via `apt` after adding the official PostgreSQL repository:
```sh
# First, add the PostgreSQL repository (see https://www.postgresql.org/download/)
sudo apt install postgresql-16-h3
```
Then, connect to your database and run:
```sql
CREATE EXTENSION h3;
CREATE EXTENSION h3_postgis CASCADE;
```

**c) Database Credentials:**
The build scripts require database credentials to be set as environment variables. Add the following to your `~/.bashrc` or `~/.profile`:
```sh
export PGUSER=<your_postgres_user>
export PGPASSWORD=<your_postgres_password>
```

### 2. Build Process

The entire data generation pipeline is managed by the `makefile`.

*   **`make all` (or just `make`)**
    This is the main command. It runs the full pipeline, which performs the following steps:
    1.  Creates the necessary tables in the `h3` schema in your PostGIS database.
    2.  Executes the SQL scripts in `sql-scripts/` to perform the generalization.
    3.  Exports the generalized geometries into Shapefiles located in the `data/export/` directory.
    4.  Generates the final `mapnik.xml` style file required for rendering.

*   **`make clean`**
    This command removes all generated files and drops the `h3` schema from the database, allowing you to start the process from scratch.

*   **`make import_planet` / `make update_db`**
    These targets are for managing the OSM data itself, either by performing a full import or by updating the database with the latest changes from OSM. These are long-running processes.

### 3. Testing the Installation

To verify that everything is set up correctly, run:
```sh
make test
```
This command will render a small sample map of the world to `landcovers_test_render.png` and compare it with the reference image `landcovers_test_render_sample.png`. If the script completes without errors, your installation is working correctly.

![Test Render Sample](landcovers_test_render_sample.png)

Once `make all` has completed successfully, the generated `mapnik.xml` can be used with a tile server to render the map.

## Discussion

For questions, feedback, and discussion, please visit the thread on the **[OpenStreetMap Community Forum](https://community.openstreetmap.org/t/announcement-openlandcovermap)**.

## License

The source code for this project is created by Zkir and is released under the **[MIT License](LICENSE.md)**. The map patterns and symbols are largely borrowed from the [openstreetmap-carto](https://github.com/gravitystorm/openstreetmap-carto) project.