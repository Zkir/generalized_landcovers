### Prerequisites

* GNU make
* wget
* zip/unzip
* python3

* ogr2ogr

* postgresql, postgis and h3 extension (version 16)

* osm2pgsql (1.10+)




We need to create database gis (preferably on separate disk, because it is huge, and also a role for the current user to access it. )


### Informational Architecture

	   o 
	   ↓
	   ↓  aria2c, osmupdate
	   ↓    
	planet.osm.pbf
	   ↓
	   ↓  osm2pgsql
	   ↓
		postgress DB, (imported planet)   
	   ↓
	   ↓  generalization scripts (generalized_landcovers)
	   ↓ 
	(generalized data, per hexes)   
	   ↓  ↓ 
	   ↓  ↓ statistics scripts, mainly pithon (generalized_landcovers)
	   ↓  ↓
	some statistics    
	   ↓    
	   ↓ ogr2ogr
	   ↓  
	resulting shape files
	   ↓  
	   ↓ tilemill  
	   ↓  
	landcovers.mbtiles (main resulting file)
	
	
### TODO

* touch _imported_planet, not a phony task