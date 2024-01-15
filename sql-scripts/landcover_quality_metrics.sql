SET statement_timeout = 0;
/*
  let's find quality(coverage) for each sell 
*/
/*
  Percentage of coverage.
  precise way: polygons are joined to find the covered area of each hex
*/
CREATE TABLE h3.landcover_quality AS
    SELECT g1.ix, g1.filled_area/ST_Area(h3.hex.geom) AS filled_rate , h3.hex.geom AS geom
       FROM (
            SELECT ix, ST_area(ST_Multi((ST_Union(f.clipped_geom))))  AS filled_area, COUNT(1) --   ROUND(SUM(st_area(clipped_geom)))
              FROM  h3.landcovers_clipped   AS f
              GROUP BY ix) g1    
        INNER JOIN h3.hex on  h3.hex.ix = g1.ix ;

/* 
  Alternative indicator for quality. 
  quick and dirty. Areas of all features are just summed up. 
  Total can be greater than 1, and it means that there are too many overlappping polygons there
*/

CREATE TABLE h3.landcover_quality2 AS    
    SELECT g1.ix, g1.filled_area/ST_Area(h3.hex.geom) AS filled_rate , h3.hex.geom AS geom
    FROM
        (SELECT ix,  SUM(srid_area) AS filled_area
                FROM  h3.hex_features_stats  
                GROUP BY ix) g1
          INNER JOIN h3.hex on h3.hex.ix = g1.ix;
          
          
/*
  are there too big polygons?  
*/          
CREATE TABLE h3.landcover_quality3 AS    
    SELECT g1.ix, max_polygon_area, geom
    from
        (SELECT ix, MAX(orig_area) AS max_polygon_area 
            FROM  h3.landcovers_clipped  
            GROUP BY ix) g1
    INNER JOIN h3.hex on h3.hex.ix = g1.ix;
