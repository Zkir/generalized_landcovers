/*
 *  we need to somewhat recreate h3.feature_stats table,
 *  because we have deleted sub-threshold values, 
 * but we need them for the Empty Hex Inspector feature 
 */

DROP TABLE IF EXISTS h3.hex_features_stats2; 
/* Note:
 *   we can use h3.no_landcover istead of h3.hex!
 */

CREATE TABLE h3.hex_features_stats2 AS
    SELECT g1.*, st_area(geom) AS hex_area, srid_area/st_area(geom) AS area_rate, geom 
        FROM ( 
            SELECT ix, feature, COUNT(1), SUM(st_area(clipped_geom)) AS srid_area 
              FROM  h3.landcovers_clipped  
              GROUP BY ix, feature
            ) g1
        INNER JOIN h3.no_landcover ON h3.no_landcover.ix = g1.ix;