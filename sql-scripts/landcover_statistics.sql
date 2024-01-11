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
          ORDER BY 5 DESC ;


-- SELECT * from h3.landcover_tag_stats ORDER BY size_in_hex DESC; 

--SELECT count(1), sum(size_in_hex), size_in_hex>20 from h3.landcover_tag_stats group by size_in_hex>20; 

/*

== to be rendered == 
...

== not clear  == 

winter_sports -- significant areas in france and italy, in Alps
recreation_ground  -- not clear what to do with it. is it something like park? - ignore? transform to built_up
railway -- also not clear. 
forestry -- not clear is it the same thing as forest

plant_nursery  -- can be any type of vegetation, from flowers to trees. 
    https://wiki.openstreetmap.org/wiki/Tag%3Alanduse%3Dplant_nursery
    
    
    
== missing bare ground ==

ground   -- natural=ground
bare_earth -- natural=bare_earth are undocumented tag for ground without vegetation, related to landcover=bare_ground, compare with bare_rock

== argiculture, possibly should be transformed ==


animal_keeping -->farmyard
agriculture
agricultural
pasture -->meadow,  landuse=pasture should be landuse=medadow+meadow=pasture
farm
field



== other==
gorge  -- natural=gorge not a landcover, but a landfeature

landslide -- ?

windfarm, wind_farm -- not clear what it is. landuse=wind_farm is not a proper feature, because wind_farms are located over some other landcover, usually farmland

oil_field, oilfield -- areas with oil or gass wells. does not imply a landcover. 

observatory -- landuse = observatory -- deprecated, but it is still used. seems to have a right to existance

dry_lake
playa -- is the same as dry_lake?





==WTF?==






*/







