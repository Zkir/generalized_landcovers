SET statement_timeout = 0;
drop table IF EXISTS  h3.water_bodies;
drop table IF EXISTS  h3.water_bodies_aggr;
--drop table IF EXISTS  h3.water_bodies_aggr_m;
CREATE TABLE h3.water_bodies AS 
	SELECT 
	  osm_id,
	  'water' AS feature,
	  Round(ST_Area(way)) AS srid_area,
	  ST_Buffer(way,500) AS geom
	  FROM planet_osm_polygon
	  WHERE "natural"='water'
	         AND ST_Area(way)>20000000;
  
CREATE INDEX gix_h3_water_bodies ON h3.water_bodies USING GIST (geom);  

SELECT 'Number of water bodies for aggregation' as feature, COUNT(1) as count FROM h3.water_bodies;


/* create generalized water bodies*/
CREATE TABLE h3.water_bodies_aggr AS 
	SELECT 'water' as feature,
		     (ST_dump(  ST_Union(f.geom)  )).geom  as geom  	    
		 FROM h3.water_bodies As f
	--GROUP BY feature;
	


UPDATE h3.water_bodies_aggr  SET geom=ST_Buffer(geom,-500);
DELETE FROM h3.water_bodies_aggr WHERE ST_Area(geom)<100000000;


SELECT *, Round(ST_Area(geom)) 
  FROM h3.water_bodies_aggr 
  ORDER BY 3 desc;

--SELECT sum(ST_NPoints(geom)) from h3.water_bodies ;
--SELECT sum(ST_NPoints(geom)) from h3.water_bodies_aggr;

