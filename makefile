.PHONY: all
all: data/shapes \
      mapnik_carto_generated.xml \
      taginfo.json \
      data/export/landcovers.mbtiles \
      data/tables/landcover_quality_metrics

.PHONY: upload
upload: data/export/landcovers.mbtiles
	if [ -z "$(FTPUSER)" ] ; then   echo "FTPUSER env variable is not defined" ; exit 1; fi
	if [ -z "$(FTPPASSWORD)" ] ; then   echo "FTPPASSWORD env variable is not defined" ; exit 1; fi
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ renderedtags.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/server/ landcovers.mbtiles

data/export/landcovers.mbtiles: data/shapes  | data/export
	node ../tilemill/index.js export generalized_landcovers  data/export/landcovers.mbtiles --format=mbtiles --minzoom=0 --maxzoom=8

taginfo.json: *.mss data/tables/landcovers_aggr data/tables/landcover_tag_stats
	python3 taginfo_json.py
	check-jsonschema "taginfo.json" --schemafile "taginfo-project-schema.json" || echo ERROR: taginfo.json does not validate against JSON schema 

mapnik_carto_generated.xml: *.mml *.mss
	carto project.mml > mapnik_carto_generated.xml

data/shapes: data/landcovers_aggr.shp \
      data/waterbodies_aggr.shp \
      data/ocean_lz.shp \
      data/places.shp \
      data/peaks.shp \
      data/ne_10m_admin_0_boundary_lines_land.shp \
      data/ne_110m_admin_0_boundary_lines_land.shp
	touch $@ 

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
	unzip -o -d data $<
	touch $@

data/ne_110m_admin_0_boundary_lines_land.shp: data/downloads/ne_110m_admin_0_boundary_lines_land.zip
	unzip -o -d data $<
	touch $@

data/tables/landcover_tag_stats: data/tables/landcovers_aggr
	psql -d gis -f "sql-scripts/landcover_statistics.sql" -v ON_ERROR_STOP=1
	touch $@


data/tables/peaks: data/tables/h3_hexes
	psql -d gis -f "sql-scripts/peaks.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/places: data/tables/h3_hexes
	psql -d gis -f "sql-scripts/places.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/water_bodies_aggr: data/tables/h3_hexes
	psql -d gis -f "sql-scripts/gen_water_bodies.sql" -v ON_ERROR_STOP=1
	touch $@


data/tables/landcover_quality_metrics: data/tables/landcovers_aggr 
	psql -d gis -f "sql-scripts/landcover_quality_metrics.sql" -v ON_ERROR_STOP=1
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

data/export:
	mkdir $@

.PHONY: test
test: 
	python3 test.py

.PHONY: clean
clean:
	psql -d gis -c "DROP SCHEMA IF EXISTS  h3 CASCADE" -v ON_ERROR_STOP=1
	rm -rf data/* 
	mkdir data/downloads
	mkdir data/tables