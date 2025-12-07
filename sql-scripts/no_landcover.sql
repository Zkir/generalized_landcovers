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

--CREATE INDEX ON h3.no_landcover (ix);
CREATE INDEX ON h3.no_landcover USING GIST (geom);