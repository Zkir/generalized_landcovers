/*
   We will create the table h3.peaks containg peaks/elevations, and will calculate importance score using Discrete Isolation method.
   Since there are already ~500,000 in OSM, and Discrete Isolation is of quadratic complexity (250 000 000 000 pairs!), 
   we need to employ some kind of combined method, use h3 grid to reduce number of pairs 
*/

SET statement_timeout = 0;

--DROP TABLE h3.peaks_pre;
--DROP TABLE h3.peaks;

CREATE TABLE h3.peaks_pre AS 
  SELECT t1.*, h3.hex.ix FROM 
    (SELECT osm_id,
           "name", 
            tags['name:en'] AS name_en,
            "natural",
            CASE
                WHEN (tags['ele'] ~ '^[0-9]*[.]*[0-9]*$') THEN (tags['ele'])::numeric
                ELSE NULL
            END AS ele,
            tags['wikidata'] AS wikidata,
            --tags, 
            way AS geom 
        FROM planet_osm_point 
        WHERE "natural" is not NULL 
--            AND "natural"  IN ('peak','saddle','pass','volcano','hill')
              AND "natural"  NOT IN ('tree', 'bay', 'beach')
              AND tags['ele'] IS NOT NULL 
              AND "name" IS NOT NULL) t1
    INNER JOIN h3.hex ON ST_Intersects(h3.hex.geom, t1.geom) AND h3.hex.resolution=2
    WHERE ele IS NOT NULL 
    ORDER BY ele desc; 

CREATE INDEX gix_h3_peaks_pre ON h3.peaks_pre USING GIST (geom);
CREATE INDEX ele_h3_peaks_pre ON h3.peaks_pre USING BTree(ele);
CREATE INDEX id_h3_peaks_pre ON  h3.peaks_pre(osm_id);
CREATE INDEX ix_h3_peaks_pre ON h3.peaks_pre(ix);
    

--SELECT count(*) FROM h3.peaks_pre; 

/* 
SELECT "natural",COUNT(1),MIN(ele), MAX(ele), ROUND(AVG(ele)) FROM h3.peaks_pre
   GROUP BY "natural"       
   ORDER BY 4 DESC;

SELECT SUM(peak_count*peak_count) FROM (
    SELECT ix, COUNT(1)AS peak_count FROM h3.peaks_pre GROUP BY ix ORDER BY 2 DESC
    ) t1; -- 140 223 320 pairs records took 168 seconds (3m) in further processing
    
SELECT distinct ix FROM h3.peaks_pre;
*/


/* 
  first of all we calculate score Discrete Isolation for each sell separately.
*/
   
CREATE TABLE h3.peaks AS    
   SELECT t0.*, t4.score AS score FROM h3.peaks_pre t0 LEFT JOIN (    -- COALESCE (t4.score,400000000) AS score
        SELECT t1.osm_id, 
               ROUND(MIN( st_distance(ST_Transform(t1.geom,4326)::geography, ST_Transform(t2.geom,4326)::geography))) AS score
            FROM  h3.peaks_pre t1
            LEFT OUTER JOIN h3.peaks_pre t2 ON (t2.ele>t1.ele) AND (t1.ix=t2.ix) -- maybe we can try also ST_DWithin
            GROUP BY t1.osm_id) t4
        ON t0.osm_id=t4.osm_id   
        ORDER BY score DESC ;
        
       

/* 
  the highest peak within each sell does not get any score value,
  so we need to calculate score for peaks that still have null scores .
*/
   
   
UPDATE 
  h3.peaks t0   
SET 
  score = COALESCE(t4.score2,40000000) -- default value is the earth equator length.
FROM 
   (SELECT t1.osm_id, 
               ROUND(MIN( st_distance(ST_Transform(t1.geom,4326)::geography, ST_Transform(t2.geom,4326)::geography))) AS score2
            FROM  h3.peaks t1
            LEFT OUTER JOIN h3.peaks t2 ON (t2.ele>t1.ele)
            where  (t1.score IS NULL) AND (t2.score IS NULL)
            GROUP BY t1.osm_id) t4 

WHERE 
  t0.osm_id=t4.osm_id ;
   
            
         
--SELECT LOG(2.0, (1+score)::numeric ),* FROM h3.peaks ORDER BY score desc;            
          
      
