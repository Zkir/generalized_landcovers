 
  
--drop table h3.places
  
CREATE TABLE h3.places AS
SELECT *,
       RANK() OVER(PARTITION BY r1ix
                   /* ORDER BY admin_level ASC,*/ population DESC) Rank
FROM
    (SELECT osm_id,
            place,
            "name",
            admin_level,
            (CASE
                 WHEN (tags->'population' ~ '^[0-9]{1,8}$') THEN (tags->'population')::INTEGER
                 WHEN (place = 'city') THEN 100000
                 WHEN (place = 'town') THEN 1000
                 ELSE 1
             END) population,
            way AS geom,
            h3.hex.ix AS r1ix
     FROM planet_osm_point
     INNER JOIN h3.hex ON ST_Intersects(h3.hex.geom, planet_osm_point.way)
     WHERE place IN ('city',
                     'town')
         AND h3.hex.resolution=1 ) t1
ORDER BY r1ix ASC,
         population DESC;
  

SELECT * FROM h3.places WHERE admin_level IS NOT NULL ORDER BY r1ix asc, rank asc;