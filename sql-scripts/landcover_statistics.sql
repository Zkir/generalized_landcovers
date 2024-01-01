SET statement_timeout = 0;

SELECT tags['desert'] 
FROM planet_osm_polygon 
WHERE "natural"='desert'


--SELECT COUNT(1) FROM h3.landcovers;

--SELECT feature, COUNT(1), round(sum(st_area(geom))) FROM h3.landcovers
--GROUP BY feature
--ORDER BY 3 desc;
--SELECT COUNT(1) FROM h3.landcovers_clipped;   
--SELECT * from h3.hex_features_stats order by ix asc, 4 desc   


--SELECT * FROM h3.landcovers_h3 ORDER BY 4 desc;

SELECT feature, COUNT( feature), round(MAX(area_rate)*1000)/1000 AS max_strength FROM h3.landcovers_h3 AS max_rate
GROUP BY feature 
HAVING MAX(area_rate) >=0.01
ORDER BY 2 desc;    


-- and some statistics: max area of generalized polygon for each feature. If max polygon is huge then feature is important.
SELECT feature FROM 
    (SELECT t1.*, t2.size_in_hex  FROM (
            Select feature, COUNT(1) as COUNT, Round(Log(MAX(ST_Area(geom)))::NUMERIC,1) AS strength
                FROM h3.landcovers_aggr
                GROUP BY feature ) t1
            INNER JOIN (
                SELECT feature, Count(geom) AS size_in_hex FROM	h3.landcovers_h3
                GROUP BY feature 
                ) t2 ON t1.feature=t2.feature    
                 
      ORDER BY 3 DESC
      LIMIT 50
      ) t1;





/*

-- transform
ice --> is not it the same thing as glacier?

rock, stone  -- is just a single notable rock/stone, not a landcover like 'blockfield.


paddy --> farmland?? paddy is a rice field 
greenhouse_horticulture -- this is rather built_up. Since greenhouse is a building. 
animal_keeping
agricultural
pasture -->meadow  landuse=pasture should be meadow=pasture


moor -- deprecated.
barren??

railway

recreation_ground -- it's something like partk

forestry -- not clear is it the same thing as forest



aquaculture -- landuse=aquaculture -- not completely clear :  "there is no convention on the exact meaning of this tag."Ы






windfarm -- not clear what it is
observatory -- landuse = observatory -- deprecated. 

playa -- is the same as dry_lake?

==WTF?==
spoils
ground
inlet

epicentre
objectiv
project
survey_area
not_meadow
property
unknown
ownership

==mistypes=



*/

SELECT * FROM h3.landcover_quality2 ORDER BY 2 DESC;



SELECT COUNT(*) FROM  planet_osm_polygon WHERE "natural"='wood' -- 9 686 112
UNION
SELECT COUNT(*) FROM  planet_osm_polygon WHERE "natural"='wood' AND (tags['leaf_type'] IS NOT NULL OR tags['leaf_cycle'] IS NOT NULL)
; 


SELECT * FROM  planet_osm_polygon WHERE "natural"='wood' AND (tags['leaf_type'] IS NOT NULL OR tags['leaf_cycle'] IS NOT NULL);



SELECT * FROM hex_features_stats WHERE ix='86390c377ffffff' ORDER BY 4 DESC;


SELECT * FROM h3.landcovers_clipped limit 100;