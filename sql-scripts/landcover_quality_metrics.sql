SET statement_timeout = 0;
/*
  let's find quality(coverage) for each sell 
*/
/*
  Percentage of coverage.
  precise way: polygons are joined to find the covered area of each hex
*/
DROP TABLE IF EXISTS h3.landcover_quality;

CREATE TABLE h3.landcover_quality AS
    SELECT h.ix, COALESCE(g1.filled_area/ST_Area(h.geom),0) AS filled_rate , h.geom AS geom
       FROM (
            SELECT ix, ST_area(ST_Multi((ST_Union(f.clipped_geom))))  AS filled_area, COUNT(1) --   ROUND(SUM(st_area(clipped_geom)))
              FROM  h3.landcovers_clipped   AS f
              GROUP BY ix) g1    
        RIGHT JOIN h3.hex_land h ON  h.ix = g1.ix ;

/* 
  Alternative indicator for quality. 
  quick and dirty. Areas of all features are just summed up. 
  Total can be greater than 1, and it means that there are too many overlappping polygons there
*/
DROP TABLE IF EXISTS h3.landcover_quality2;
CREATE TABLE h3.landcover_quality2 AS    
    SELECT h.ix, COALESCE(g1.filled_area/ST_Area(h.geom),0) AS filled_rate , h.geom AS geom
    FROM h3.hex_land h 
	LEFT JOIN
        (SELECT ix,  SUM(srid_area) AS filled_area
                FROM  h3.hex_features_stats  
                GROUP BY ix) g1
        on h.ix = g1.ix;
          
          
/*
  Are there too big polygons?  
*/       
DROP TABLE IF EXISTS h3.landcover_quality3;
CREATE TABLE h3.landcover_quality3 AS    
    SELECT g1.ix, max_polygon_area, geom
    FROM
        (SELECT ix, MAX(orig_area) AS max_polygon_area 
            FROM  h3.landcovers_clipped  
            GROUP BY ix) g1
    INNER JOIN h3.hex on h3.hex.ix = g1.ix;


/*
 * Empty land hexes. We need them for the Hex Inspector feature.
 */

DROP TABLE IF EXISTS h3.no_landcover;
CREATE TABLE h3.no_landcover AS 
	SELECT ix, geom
	    FROM h3.hex_land hl 
	    WHERE NOT EXISTS(
	        SELECT 1 
	           FROM h3.landcovers_h3 lh3 
	           WHERE cast(hl.ix AS VARCHAR(16)) = lh3.ix)
	   AND ST_Y(ST_Transform(ST_Centroid(geom), 4326)) > -60;      

   
	   