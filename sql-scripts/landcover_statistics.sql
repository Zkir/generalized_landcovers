/*
    He we  create some tables to store tag usage statistics
    it is used to generate taginfo.json file for our taginfo project
*/
SET statement_timeout = 0;


-- drop table h3.source_tag_list
CREATE TABLE h3.source_tag_list AS 
    (SELECT 'natural' AS "key" , "natural"  AS "value", COUNT(1) AS "count"  
        FROM planet_osm_polygon
        where ( planet_osm_polygon."natural" IS NOT NULL)
        GROUP BY "natural"
    )
    union
    (SELECT DISTINCT 'landuse' AS "key" , "landuse"  AS "value" , COUNT(1) AS "count"
        FROM planet_osm_polygon
        where (planet_osm_polygon.landuse IS NOT NULL )
        GROUP BY "landuse"
    )
;

/*
    we will select single key for each value, not to have both natural=forest and landuse=forest, which both(!) exist in the source list
*/
CREATE TABLE h3.source_tag_list2 AS 
    SELECT t1.* 
        FROM h3.source_tag_list t1
        INNER JOIN (
          SELECT "value", MAX( "count" ) as max_count
          FROM h3.source_tag_list
          GROUP BY "value" ) t2
          ON t1.value = t2.value AND t1.count = max_count
    ORDER BY 3 DESC;        

-- and some statistics: max area of generalized polygon for each feature. If max polygon is huge then feature is important.
CREATE TABLE h3.landcover_tag_stats as
    SELECT t3."key", t1.*    FROM 
        (SELECT t1.*, t2.size_in_hex  FROM (
                Select feature, COUNT(1) as COUNT, Round(Log(MAX(ST_Area(geom)))::NUMERIC,1) AS strength
                    FROM h3.landcovers_aggr
                    GROUP BY feature ) t1
                INNER JOIN (
                    SELECT feature, Count(geom) AS size_in_hex FROM	h3.landcovers_h3
                    GROUP BY feature 
                    ) t2 ON t1.feature=t2.feature    
                     
          ) t1
          LEFT OUTER JOIN  h3.source_tag_list2 t3 ON t1.feature=t3."value" 
          ORDER BY 5 DESC
          LIMIT 100;


-- SELECT * from h3.landcover_tag_stats ORDER BY strength DESC; 

/*

-- transform
ice --> is not it the same thing as glacier?

paddy --> farmland?? paddy is a rice field 
greenhouse_horticulture -- this is rather built_up. Since greenhouse is a building. 
animal_keeping
agricultural
pasture -->meadow,  landuse=pasture should be landuse=medadow+meadow=pasture


moor -- deprecated.
barren??

railway

recreation_ground -- it's something like park
winter_sports -- should it be accepted by landcovers

forestry -- not clear is it the same thing as forest




windfarm, wind_farm -- not clear what it is. landuse=wind_farm is not a proper feature, because wind_farms are located over some other landcover, usually farmland

observatory -- landuse = observatory -- deprecated, but it is still used.

dry_lake
playa -- is the same as dry_lake?

oil_field
oilfield



==WTF?==
spoils
ground
inlet



property
unknown
ownership


*/







