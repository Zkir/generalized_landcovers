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
            tags, 
            way AS geom 
        FROM planet_osm_point 
        WHERE "natural" is not NULL 
--            AND "natural"  IN ('peak','saddle','pass','volcano','hill')
              AND "natural"  NOT IN ('tree')
              AND tags['ele'] IS NOT NULL 
              AND "name" IS NOT NULL) t1
    INNER JOIN h3.hex ON ST_Intersects(h3.hex.geom, t1.geom) AND h3.hex.resolution=2
    WHERE ele IS NOT NULL 
    ORDER BY ele desc
    LIMIT 2000000; -- 40,000 records took 3 mintues to process;

CREATE INDEX gix_h3_peaks_pre ON h3.peaks_pre USING GIST (geom);
CREATE INDEX ele_h3_peaks_pre ON h3.peaks_pre USING BTree(ele);
CREATE INDEX id_h3_peaks_pre ON  h3.peaks_pre(osm_id);
CREATE INDEX ix_h3_peaks_pre ON h3.peaks_pre(ix);
    

--SELECT * FROM h3.peaks_pre; 


SELECT "natural",COUNT(1),MIN(ele), MAX(ele), ROUND(AVG(ele)) FROM h3.peaks_pre
   GROUP BY "natural"       
   ORDER BY 4 DESC;

SELECT SUM(peak_count*peak_count) FROM (
    SELECT ix, COUNT(1)AS peak_count FROM h3.peaks_pre GROUP BY ix ORDER BY 2 DESC
    ) t1; -- 140 223 320 pairs records took 168 seconds (3m) in further processing
    
SELECT distinct ix FROM h3.peaks_pre;
   
CREATE TABLE h3.peaks AS    
   SELECT t0.*, COALESCE (t4.score,400000000) AS score FROM h3.peaks_pre t0 LEFT JOIN (   
        SELECT t1.osm_id, 
               ROUND(MIN( st_distance(ST_Transform(t1.geom,4326)::geography, ST_Transform(t2.geom,4326)::geography))) AS score
            FROM  h3.peaks_pre t1
            LEFT OUTER JOIN h3.peaks_pre t2 ON (t2.ele>t1.ele) AND (t1.ix=t2.ix)
            GROUP BY t1.osm_id) t4
        ON t0.osm_id=t4.osm_id   
        ORDER BY score DESC ;
        
        
        
SELECT * FROM h3.peaks ORDER BY Score DESC;        
        
        
      
