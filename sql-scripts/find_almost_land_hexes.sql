/* 
   Here we find hexes, mostly occupied by land.
   We need them for more precise landcover quality metrics, and also for the empty hex finder.
*/

SET statement_timeout = 0;
DROP INDEX IF EXISTS gix_simplified_water_polygons;
CREATE INDEX gix_simplified_water_polygons ON simplified_water_polygons USING GIST (way);

CREATE TABLE h3.hex_water AS
		-- Hexes covered by inland water from aggregated water bodies
        SELECT h.ix
        FROM h3.hex h
        JOIN h3.water_bodies_aggr w ON ST_Intersects(h.geom, w.geom)
        WHERE h.resolution = 6
        AND ST_Area(ST_Intersection(h.geom, w.geom)) > (ST_Area(h.geom) * 0.5)
        UNION
        -- Hexes covered by ocean from simplified water polygons
        SELECT h.ix
        FROM h3.hex h
        JOIN simplified_water_polygons o ON ST_Intersects(h.geom, o.way)
        WHERE h.resolution = 6
        AND ST_Area(ST_Intersection(h.geom, o.way)) > (ST_Area(h.geom) * 0.5);
		
CREATE INDEX ix_h3_hex_water ON h3.hex_water(ix);

CREATE TABLE h3.hex_land AS
  SELECT h.ix, h.geom
  FROM h3.hex h
  WHERE h.resolution = 6
  AND NOT EXISTS (SELECT 1 FROM h3.hex_water hw WHERE hw.ix = h.ix);

CREATE INDEX ix_h3_hex_land ON h3.hex_land(ix);
CREATE INDEX gix_h3_hex_land ON h3.hex_land USING GIST (geom);