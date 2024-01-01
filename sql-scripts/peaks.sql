SET statement_timeout = 0;

--DROP TABLE misc.peaks;
--DROP TABLE h3.peaks;

CREATE TABLE misc.peaks AS 
SELECT * FROM 
    (SELECT osm_id,
           "name", 
            tags['name:en'] AS name_en,
            "natural",
            CASE
                WHEN (tags['ele'] ~ '^[0-9]*[.]*[0-9]*$') THEN (tags['ele'])::numeric
                ELSE NULL
            END AS ele,
            tags['wikidata'] AS wikidata,
            tags, 
            way AS geom 
        FROM planet_osm_point 
        WHERE "natural" is not NULL 
--            AND "natural"  IN ('peak','saddle','pass','volcano','hill')
              AND "natural"  NOT IN ('tree')
              AND tags['ele'] IS NOT NULL 
              AND "name" IS NOT NULL) t1
    WHERE ele IS NOT NULL 
    ORDER BY ele desc
    LIMIT 40000; --20000;

CREATE INDEX gix_misc_peaks ON misc.peaks USING GIST (geom);
CREATE INDEX id_misc_peaks ON misc.peaks(osm_id);
CREATE INDEX ele_misc_peaks ON misc.peaks USING BTree(ele);
    

SELECT * FROM misc.peaks; 


SELECT "natural",COUNT(1),MAX(ele), ROUND(AVG(ele)) FROM misc.peaks
   GROUP BY "natural"       
   ORDER BY 3 DESC;


   
CREATE TABLE h3.peaks AS    
    SELECT t0.*, t4.score FROM misc.peaks t0 LEFT JOIN (   
        SELECT t1.osm_id, 
               ROUND(MIN( st_distance(ST_Transform(t1.geom,4326)::geography, ST_Transform(t2.geom,4326)::geography))) AS score
            FROM  misc.peaks t1
            LEFT OUTER JOIN misc.peaks t2 ON t2.ele>t1.ele
            GROUP BY t1.osm_id) t4
        ON t0.osm_id=t4.osm_id   
        ORDER BY score DESC ;
        
        
        
SELECT * FROM h3.peaks ORDER BY Score DESC;        
        
        
      
