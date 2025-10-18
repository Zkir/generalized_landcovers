.PHONY: all
all: data/tables/landcover_quality_metrics \
      data/shapes \
      mapnik_carto_generated.xml \
      taginfo.json \
      data/export/landcovers.mbtiles \
      data/export/downloads.html \
      data/export/country_stats.html \
      data/export/about.html \
      data/export/index.html


.PHONY: upload
upload: data/export/landcovers.mbtiles
	if [ -z "$(FTPUSER)" ] ; then   echo "FTPUSER env variable is not defined" ; exit 1; fi
	if [ -z "$(FTPPASSWORD)" ] ; then   echo "FTPPASSWORD env variable is not defined" ; exit 1; fi
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/landcovers.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/peaks.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/places.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ about.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ renderedtags.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ country_stats.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/server/ landcovers.mbtiles

data/export/index.html: | data/export
	cp webui-prototypes/index.html data/export/index.html

data/export/about.html: | data/export
	cp webui-prototypes/about.html data/export/about.html

data/export/country_stats.html: data/tables/country_stats
	python3 py-scripts/country_stats.py

data/export/downloads.html:      data/export/downloads/landcovers.zip  data/export/downloads/peaks.zip  data/export/downloads/places.zip 
	python3 py-scripts/downloads.py

data/export/landcovers.mbtiles: data/shapes  | data/export
	node ../tilemill/index.js export generalized_landcovers  data/export/landcovers.mbtiles --format=mbtiles --minzoom=0 --maxzoom=8 --quiet

taginfo.json: *.mss data/tables/landcovers_aggr data/tables/landcover_tag_stats | data/export
	python3 py-scripts/taginfo_json.py
	check-jsonschema "taginfo.json" --schemafile "taginfo-project-schema.json" || echo ERROR: taginfo.json does not validate against JSON schema 

mapnik_carto_generated.xml: *.mml *.mss
	carto project.mml > mapnik_carto_generated.xml

data/export/downloads/landcovers.zip: data/landcovers_aggr.shp | data/export/downloads
	zip -j $@ data/landcovers_aggr.* misc/landcovers.readme.txt

data/export/downloads/peaks.zip: data/peaks.shp | data/export/downloads
	zip -j $@ data/peaks.* misc/peaks.readme.txt

data/export/downloads/places.zip: data/places.shp | data/export/downloads
	zip -j $@ data/places.* misc/places.readme.txt

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

data/tables/country_stats:  data/tables/ne_10m_admin_0_countries data/tables/landcovers_aggr
	psql -d gis -f "sql-scripts/country_stats.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/ne_10m_admin_0_countries: data/ne_10m_admin_0_countries.shp
	ogr2ogr -f "PostgreSQL" \
                       "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
                       data/ne_10m_admin_0_countries.shp \
                       -nlt PROMOTE_TO_MULTI \
                      -nln h3.ne_10m_admin_0_countries \
                      -progress -overwrite 
	touch $@


#ogr2ogr -f PostgreSQL PG:"dbname='shape' host='127.0.0.1' port='5434' user='geosolutions' password='Geos'" ../data/user_data/Mainrd.shp -lco #GEOMETRY_NAME=geom -lco FID=gid -lco SPATIAL_INDEX=GIST -nlt PROMOTE_TO_MULTI -nln main_roads_2 -overwrite


data/ne_10m_admin_0_boundary_lines_land.shp: data/downloads/ne_10m_admin_0_boundary_lines_land.zip
	unzip -o -d data $<
	touch $@

data/ne_110m_admin_0_boundary_lines_land.shp: data/downloads/ne_110m_admin_0_boundary_lines_land.zip
	unzip -o -d data $<
	touch $@

data/ne_10m_admin_0_countries.shp: data/downloads/ne_10m_admin_0_countries.zip
	unzip -o -d data $<
	touch $@

data/tables/landcover_tag_stats: data/tables/landcovers_aggr | data/tables
	psql -d gis -f "sql-scripts/landcover_statistics.sql" -v ON_ERROR_STOP=1
	touch $@


data/tables/peaks: data/tables/h3_hexes | data/tables
	psql -d gis -f "sql-scripts/peaks.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/places: data/tables/h3_hexes | data/tables
	psql -d gis -f "sql-scripts/places.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/water_bodies_aggr: data/tables/h3_hexes | data/tables
	psql -d gis -f "sql-scripts/gen_water_bodies.sql" -v ON_ERROR_STOP=1
	touch $@


data/tables/landcover_quality_metrics: data/tables/landcovers_aggr | data/tables
	psql -d gis -f "sql-scripts/landcover_quality_metrics.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/landcovers_aggr: data/tables/h3_hexes | data/tables
	psql -d gis -f "sql-scripts/gen_land_covers.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/h3_hexes: | data/tables
	psql -d gis -f "sql-scripts/prepare_h3_hexes.sql" -v ON_ERROR_STOP=1
	touch $@

data/downloads/ne_10m_admin_0_boundary_lines_land.zip: | data/downloads
	wget -O $@ http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_boundary_lines_land.zip

data/downloads/ne_110m_admin_0_boundary_lines_land.zip: | data/downloads
	wget -O $@ http://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_boundary_lines_land.zip

data/downloads/ne_10m_admin_0_countries.zip: | data/downloads
	wget -O $@ http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_countries.zip

data/downloads: | data
	mkdir $@

data/export/downloads: | data/export
	mkdir $@

data/export: | data
	mkdir $@

data/tables: | data
	mkdir $@

data/source: | data
	mkdir $@

data: 
	mkdir $@


data/source/planet-latest.osm.pbf: | data/source
	(cd data/source; aria2c https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent --seed-time=0)
	(cd data/source; mv planet-*.osm.pbf planet-latest.osm.pbf)

data/source/planet-latest-updated.osm.pbf: data/source/planet-latest.osm.pbf
	(cd data/source; osmupdate planet-latest.osm.pbf planet-latest-updated.osm.pbf)

.PHONY: test
test: 
	python3 test.py

.PHONY: import_planet
import_planet: data/source/planet-latest-updated.osm.pbf | data
	osm2pgsql -d gis -U $(USER) --create --slim  -G --hstore --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua -C 0 --flat-nodes data/nodes.bin --number-processes 16 -S ~/src/openstreetmap-carto/openstreetmap-carto.style -r pbf data/source/planet-latest-updated.osm.pbf
	osm2pgsql-replication init -d gis --server https://planet.openstreetmap.org/replication/hour

.PHONY: update_db
update_db: 
	osm2pgsql-replication update -d gis  --max-diff-size 100 --  -G --hstore --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua -C 0 --flat-nodes data/nodes.bin --number-processes 8 -S ~/src/openstreetmap-carto/openstreetmap-carto.style

.PHONY: clean
clean:
	psql -d gis -c "DROP SCHEMA IF EXISTS  h3 CASCADE" -v ON_ERROR_STOP=1
	rm -rf data/* 
	mkdir data/downloads
	mkdir data/tables
