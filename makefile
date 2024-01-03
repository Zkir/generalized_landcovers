all: data/landcovers_aggr.shp  data/waterbodies_aggr.shp data/places.shp data/peaks.shp mapnik_carto_generated.xml

mapnik_carto_generated.xml: *.mml *.mss
	carto project.mml > mapnik_carto_generated.xml

data/landcovers_aggr.shp: data/tables/landcovers_aggr
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/landcovers_aggr.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
  -sql "SELECT * FROM h3.landcovers_aggr" \
  -lco ENCODING=UTF-8

data/landcovers.gpkg: data/tables/landcovers_aggr
	ogr2ogr -f "GPKG" \
  -progress -overwrite \
  data/landcovers.gpkg \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
  -nln landcovers \
  -sql "SELECT * FROM h3.landcovers" 

data/waterbodies_aggr.shp: data/tables/water_bodies_aggr
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/waterbodies_aggr.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
  -sql "SELECT * FROM h3.water_bodies_aggr" \
  -lco ENCODING=UTF-8

data/places.shp: data/tables/places
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/places.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
  -sql "SELECT * FROM h3.places" \
  -lco ENCODING=UTF-8

data/peaks.shp: data/tables/peaks
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/peaks.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER) password=$(PGPASSWORD)" \
  -sql "SELECT * FROM h3.peaks" \
  -lco ENCODING=UTF-8

data/ocean_lz.shp: 
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/ocean_lz.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER) password=$(PGPASSWORD)" \
  -sql "SELECT * FROM simplified_water_polygons" \
  -lco ENCODING=UTF-8


data/ne_10m_admin_0_boundary_lines_land.shp: data/downloads/ne_10m_admin_0_boundary_lines_land.zip
	unzip -d data $<

data/ne_110m_admin_0_boundary_lines_land.shp: data/downloads/ne_110m_admin_0_boundary_lines_land.zip
	unzip -d data $<



data/tables/peaks: data/tables/h3_hexes
	psql -d gis -f "sql-scripts/peaks.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/places: data/tables/h3_hexes
	psql -d gis -f "sql-scripts/places.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/water_bodies_aggr: data/tables/h3_hexes
	psql -d gis -f "sql-scripts/gen_water_bodies.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/landcovers_aggr: data/tables/h3_hexes
	psql -d gis -f "sql-scripts/gen_land_covers.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/h3_hexes:
	psql -d gis -f "sql-scripts/prepare_h3_hexes.sql" -v ON_ERROR_STOP=1
	touch $@

data/downloads/ne_10m_admin_0_boundary_lines_land.zip: | data/downloads
	wget -O $@ https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_boundary_lines_land.zip

data/downloads/ne_110m_admin_0_boundary_lines_land.zip: | data/downloads
	wget -O $@ https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/110m/cultural/ne_110m_admin_0_boundary_lines_land.zip

data/downloads:
	mkdir $@

.PHONY: test
test: 
	python3 test.py

.PHONY: clean
clean:
	echo "please clean yourself"