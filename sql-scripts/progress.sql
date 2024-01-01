SELECT COUNT (*), 656280527  AS Last_value FROM planet_osm_polygon;
--SET statement_timeout = 0;
--VACUUM;

--SELECT COUNT(*) FROM planet_osm_nodes; -- 787 322 904 --7 086 449 253
--SELECT COUNT(*) FROM planet_osm_point;  

SELECT 'number of clipped polygons' as stat,count(*) FROM h3.landcovers_h3 
UNION  
select 'number of hexes' as stat, count(1) from h3.hex where resolution=6; 

SELECT COUNT(1) FROM h3.landcovers;

unuion
select COUNT(1) from h3.landcovers_clipped;


SELECT ix, filled_rate, geom FROM h3.landcover_quality ORDER BY 2 DESC;

UPDATE h3.landcover_quality SET filled_rate= Round(filled_rate::NUMERIC,3);