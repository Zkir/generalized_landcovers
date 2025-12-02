# OpenLandcoverMap

**OpenLandcoverMap** is a project designed to create generalized landcover maps from OpenStreetMap (OSM) data, specifically for zoom levels z0-z8. It addresses the common issue of standard OSM maps appearing empty and devoid of features at these lower zoom levels by providing a more visually informative and richer map rendering.

![Generalized Landcovers vs. Standard OSM](webui-prototypes/img/pic02_landcovers_vs_mapnik.png)

The live map is accessible at: **https://openlandcovermap.org**

I hope that the awesome people responsible for the slippy map at openstreetmap.org will look at our map, see what's possible,
and think hard about the future of cartographic representation in the OSM project.

## The Approach

The core idea of this project is to use a hexagonal grid system (Uber's H3) to process and generalize raw OSM data. 
For each cell in the grid, the dominant landcover type is identified, and these cells are then merged to create larger, 
more coherent polygons that are suitable for rendering at low zoom levels. 

For a detailed explanation of the various generalization techniques used for landcovers, water bodies, populated places, and mountain peaks, 
please see the **[About Page](https://openlandcovermap.org/about.html)**.

## Technology Stack

This project is built upon a foundation of powerful open-source geospatial tools:

*   **PostGIS:** A PostgreSQL extension for storing and processing complex spatial data.
*   **H3:** A hexagonal hierarchical spatial index used for the core generalization logic. The `h3-pg` extension provides the necessary database functions.
*   **osm2pgsql:** For importing raw OpenStreetMap data into the PostGIS database.
*   **Mapnik:** The core rendering engine. Styles are defined in `.mml` and `.mss` files and compiled into `mapnik.xml` using the `carto` tool. 
    This `mapnik.xml` is then used by Mapnik for rendering.
*   **Tilemill:** A powerful map design studio built on Node.js, which uses Mapnik-compatible styles. In this project, Tilemill is specifically used to *export*
    the generalized map data into efficient [MBTiles format](https://wiki.openstreetmap.org/wiki/MBTiles) for web serving.
	While Mapnik is the underlying rendering technology, directly generating web tiles with it can be difficult to configure and requires specific Apache setup;
	Tilemill streamlines this process for web deployment.
*   **Python:** For various automation scripts, data analysis, and helper tasks.
*   **GNU Make:** For orchestrating the entire data processing and build pipeline.

## Getting Started

Follow these steps to set up the project and generate the map data on your own machine.

### 1. Prerequisites

It's assumed that you have up and running OSM tile server. After all, this project is (or was initially) aimed to patch the standard OSM carto style. 
For guidance on setting up a tile server, refer to the specialized tutorial on [switch2osm.org](https://switch2osm.org/serving-tiles/manually-building-a-tile-server-ubuntu-24-04-lts/).

However, working tileserver is not really mandatory, you can run the generalization process by itself, and experiment with resulting data, using, for example, QGIS.
The following are the most important steps to configure it.

**a) OSM Data in PostGIS:**
You must have a PostGIS database (e.g., named `gis`) with OpenStreetMap data imported via `osm2pgsql`. The import command should be configured to use the `hstore` format and apply the appropriate style transformations.

A typical `osm2pgsql` command might look like this (adapt paths and parameters for your system):
```sh
osm2pgsql -d gis -U <your_user> -W --create --slim -G --hstore --tag-transform-script openstreetmap-carto.lua -C 24000 --flat-nodes /path/to/nodes.bin --number-processes 8 -S openstreetmap-carto.style /path/to/planet-latest.osm.pbf
```
`make import_planet` command contains preconfigured version of this command.

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

**c) Tilemill and Node.js:**
Tilemill is used to generate the MBTiles for the web map. It requires Node.js, and the `makefile` specifies Node.js v8.15.0.

1.  **Install Node.js (v8.15.0 recommended):** It's highly recommended to use `nvm` (Node Version Manager) to manage Node.js versions.
    ```sh
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    source ~/.bashrc # or ~/.profile
    nvm install v8.15.0
    nvm use v8.15.0
    ```
2.  **Install Tilemill:** Clone the Tilemill repository into the parent directory of this project (so it's accessible at `../tilemill` from the project root).
    ```sh
    cd ..
    git clone https://github.com/tilemillproject/tilemill.git
    cd tilemill
    npm install
    ```
    *Note: Tilemill is an older project and might require specific environment setups or dependency adjustments to run correctly on modern systems.*

**d) Database Credentials:**
The build scripts require database credentials to be set as environment variables. Add the following to your `~/.bashrc` or `~/.profile`:
```sh
export PGUSER=<your_postgres_user>
export PGPASSWORD=<your_postgres_password>
```

**e) External Shapefiles:**
The `openstreetmap-carto` style, which this project uses as a base, requires several pre-processed shapefiles for rendering certain features like coastlines. One of these is `simplified_water_polygons`. This table is not generated from the main planet import but is imported from a shapefile.

To download and import these required shapefiles:
1. Navigate to your local clone of the `openstreetmap-carto` repository.
2. Run the provided script:
   ```sh
   python3 scripts/get-external-data.py
   ```
This script will download the necessary files (like `simplified-water-polygons-split-3857.zip`), unzip them, and use `ogr2ogr` to import them into your `gis` database.

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
	It does not affect 'raw' (ungeneralized) data imported by osm2pgsql.

*   **`make import_planet` / `make update_db`**
    These targets are for managing the OSM data itself, either by performing a full import or by updating the database with the latest changes from OSM. These are long-running processes.

### 3. Testing the Installation

(_Note: this section requires some revision._ _It should be clarified when `make test` should be run and what it really tests._)

To verify that everything is set up correctly, run:
```sh
make test
```
This command will render a small sample map of the world to `landcovers_test_render.png` and compare it with the reference image `landcovers_test_render_sample.png`. 
If the script completes without errors, your installation is working correctly.


![Test Render Sample](landcovers_test_render_sample.png)

Once `make all` has completed successfully, the generated `mapnik.xml` can be used with a tile server to render the map.

## Discussion

For questions, feedback, and discussion, please visit the thread on the **[OpenStreetMap Community Forum](https://community.openstreetmap.org/t/announcement-openlandcovermap)**.

## License

The source code for this project is created by Zkir and is released under the **[MIT License](LICENSE.md)**. The map patterns and symbols are largely borrowed from the [openstreetmap-carto](https://github.com/gravitystorm/openstreetmap-carto) project.