.PHONY: all
all:  data/shapes \
      mapnik_carto_generated.xml \
      taginfo.json \
      data/export/server/landcovers.mbtiles \
	  data/export/server/.htaccess \
	  data/export/server/tileserver.php \
      data/export/downloads.html \
      data/export/country_stats.html \
      data/export/renderedtags.html \
      data/export/about.html \
      data/export/index.html \
      data/export/empty_hex.html \
      data/export/empty_hex_api.py \
      data/export/country_api.py \
      data/export/landcover_stats.sqlite \
	  data/export/img \
	  data/export/style.css ## Do generalization and create web-ui image, including downloadable files

#     data/tables/landcover_quality_metrics \
#	  data/export/downloads/unrendered_landcovers.osm \

.PHONY: upload
upload: data/export/server/landcovers.mbtiles ## Upload downloadable files and generated htmls to the web-ui
	if [ -z "$(FTPUSER)" ] ; then   echo "FTPUSER env variable is not defined" ; exit 1; fi
	if [ -z "$(FTPPASSWORD)" ] ; then   echo "FTPPASSWORD env variable is not defined" ; exit 1; fi
	cd data/export/server ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/server/ landcovers.mbtiles
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ landcover_stats.sqlite
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/landcovers.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/peaks.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/places.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/waterbodies.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads/rivers.zip
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ index.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ about.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ renderedtags.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ downloads.html
	cd data/export ; ftp -u ftp://$(FTPUSER):$(FTPPASSWORD)@osm2.zkir.ru/landcovers/ country_stats.html
	

data/export/index.html: webui-prototypes/index.html | data/export
	cp webui-prototypes/index.html data/export/index.html

data/export/about.html: webui-prototypes/about.html | data/export
	cp webui-prototypes/about.html data/export/about.html

data/export/style.css:  webui-prototypes/style.css | data/export
	cp webui-prototypes/style.css data/export/style.css

data/export/empty_hex.html: webui-prototypes/empty_hex.html | data/export
	cp webui-prototypes/empty_hex.html data/export/empty_hex.html

data/export/empty_hex_api.py: misc/empty_hex_api.py | data/export
	cp misc/empty_hex_api.py data/export/empty_hex_api.py
	chmod +x data/export/empty_hex_api.py

data/export/country_api.py: misc/country_api.py | data/export
	cp misc/country_api.py data/export/country_api.py
	chmod +x data/export/country_api.py

data/export/landcover_stats.sqlite: data/tables/features_stats2 data/tables/country_stats | data/export
	python3 py-scripts/export_stats_to_sqlite.py

data/export/country_stats.html: data/tables/country_stats
	python3 py-scripts/country_stats.py

data/export/downloads.html:      data/export/downloads/landcovers.zip  data/export/downloads/peaks.zip  data/export/downloads/places.zip data/export/downloads/waterbodies.zip data/export/downloads/rivers.zip
	python3 py-scripts/downloads.py
	
data/export/downloads/unrendered_landcovers.osm: taginfo.json planet/planet-latest-updated.osm.pbf
	python3 py-scripts/extract_unrendered.py

data/export/server/.htaccess : | data/export/server
	cp misc/tileserver/.htaccess data/export/server/.htaccess
	
data/export/server/tileserver.php : | data/export/server
	cp misc/tileserver/tileserver.php data/export/server/tileserver.php

data/export/server/landcovers.mbtiles: data/shapes  | data/export/server
	rm -f $@
	(. ~/.nvm/nvm.sh && nvm use v8.15.0 && node ../tilemill/index.js export generalized_landcovers  data/export/server/landcovers.mbtiles --format=mbtiles --minzoom=0 --maxzoom=8 --quiet)

taginfo.json data/export/renderedtags.html &: *.mss data/tables/landcovers_aggr data/tables/landcover_tag_stats | data/export
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

data/export/downloads/waterbodies.zip: data/waterbodies_aggr.shp | data/export/downloads
	zip -j $@ data/waterbodies_aggr.* misc/waterbodies.readme.txt

data/export/downloads/rivers.zip: data/rivers_gen.shp | data/export/downloads
	zip -j $@ data/rivers_gen.* misc/rivers.readme.txt
	
data/export/img: |	data/export
	mkdir data/export/img
	cp webui-prototypes/img/*.png data/export/img/
	cp misc/img/*.png data/export/img/
	cp misc/img/*.svg data/export/img/


data/shapes: data/landcovers_aggr.shp \
      data/waterbodies_aggr.shp \
      data/ocean_lz.shp \
      data/places.shp \
      data/peaks.shp \
      data/ne_10m_admin_0_boundary_lines_land.shp \
      data/ne_110m_admin_0_boundary_lines_land.shp \
      data/rivers_gen.shp
	touch $@ 

data/landcovers_aggr.shp: data/tables/landcovers_aggr
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/landcovers_aggr.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
  -sql "SELECT * FROM h3.landcovers_aggr" \
  -lco ENCODING=UTF-8

data/waterbodies_aggr.shp: data/tables/water_bodies_aggr
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/waterbodies_aggr.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
  -sql "SELECT * FROM h3.water_bodies_aggr" \
  -lco ENCODING=UTF-8

data/rivers_gen.shp: data/tables/rivers_gen
	ogr2ogr -f "ESRI Shapefile" \
  -progress -overwrite \
  data/rivers_gen.shp \
  "PG:dbname=gis host=localhost port=5432 user=$(PGUSER)  password=$(PGPASSWORD)" \
  -sql "SELECT * FROM h3.rivers_gen WHERE rank >= 2" \
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

data/tables/country_stats: data/tables/ne_10m_admin_0_countries data/tables/landcovers_aggr data/tables/hex_land data/tables/no_landcover
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
	
data/tables/landcover_quality_metrics: data/tables/landcovers_aggr data/tables/hex_land | data/tables
	psql -d gis -f "sql-scripts/landcover_quality_metrics.sql" -v ON_ERROR_STOP=1
	touch $@
	
data/tables/features_stats2: data/tables/landcovers_aggr data/tables/no_landcover 
	psql -d gis -f "sql-scripts/features_stats2.sql" -v ON_ERROR_STOP=1
	touch $@	

data/tables/no_landcover: data/tables/landcovers_aggr data/tables/hex_land 
	psql -d gis -f "sql-scripts/no_landcover.sql" -v ON_ERROR_STOP=1
	touch $@	
	
	
data/tables/hex_land: data/tables/h3_hexes data/tables/water_bodies_aggr | data/tables
	psql -d gis -f "sql-scripts/find_almost_land_hexes.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/water_bodies_aggr: data/tables/h3_hexes | data/tables
	psql -d gis -f "sql-scripts/gen_water_bodies.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/rivers_gen: data/tables/h3_hexes data/tables/waterway_areas data/tables/waterways_linear | data/tables
	osm2pgsql-gen -d gis -U $(USER) -S flex-config/waterways_gen.lua
	touch $@

data/tables/landcovers_aggr: data/tables/h3_hexes | data/tables
	psql -d gis -f "sql-scripts/gen_land_covers.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/h3_hexes: | data/tables
	psql -d gis -f "sql-scripts/prepare_h3_hexes.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/waterway_areas: | data/tables/h3_hexes
	psql -d gis -f "sql-scripts/create_waterway_areas.sql" -v ON_ERROR_STOP=1
	touch $@

data/tables/waterways_linear: | data/tables/h3_hexes
	psql -d gis -f "sql-scripts/create_waterways_linear.sql" -v ON_ERROR_STOP=1
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
	
	
data/export/server: | data/export
	mkdir $@
	
data/export: | data
	mkdir $@

data/tables: | data
	mkdir $@

planet: | data
	mkdir $@

data: 
	mkdir $@


planet/planet-latest.osm.pbf: | planet
	(cd planet; aria2c https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent --seed-time=0)
	(cd planet; mv planet-*.osm.pbf planet-latest.osm.pbf)

planet/planet-latest-updated.osm.pbf: planet/planet-latest.osm.pbf
	(cd planet; osmupdate planet-latest.osm.pbf planet-latest-updated.osm.pbf)

.PHONY: test
test: 
	python3 test.py


.PHONY: import_planet
import_planet: planet/planet-latest-updated.osm.pbf | data ## import data into DB from planet.osm.pbf
	osm2pgsql -d gis -U $(USER) --create --slim -C 0 --flat-nodes planet/nodes.bin --number-processes 16 -O flex -S flex-config/openstreetmap-carto-flex.lua -r pbf planet/planet-latest-updated.osm.pbf
	osm2pgsql-replication init -d gis --server https://planet.openstreetmap.org/replication/hour

.PHONY: update_db
update_db: ## Update DB via OSM hour diffs
	osm2pgsql-replication update -d gis  --max-diff-size 100 -- -C 0 --flat-nodes planet/nodes.bin --number-processes 16 -O flex -S flex-config/openstreetmap-carto-flex.lua

.PHONY: clean
clean: ## Delete all the *generalized* map data in DB and the files in the work folder. Raw planet data imported via osm2pgsql remains intact!
	psql -d gis -c "DROP SCHEMA IF EXISTS  h3 CASCADE" -v ON_ERROR_STOP=1
	rm -rf data/* 
	mkdir data/downloads
	mkdir data/tables


.PHONY: help
help: ## Print descriptions for tasks
	@grep -E '^[a-zA-Z][^:]*:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = " *&?:.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'	
