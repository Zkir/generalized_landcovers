/*
*  For some mysterious reason table waterway_areas is not created by osm2pgsql, 
*  but is used by osm2pgsql-gen (hardcoded)
*  so we need to create it ourselves!
*/

CREATE INDEX IF NOT EXISTS natural_planet_osm_polygon ON planet_osm_polygon("natural", "water");

DROP TABLE IF EXISTS h3.waterway_areas;

CREATE TABLE h3.waterway_areas AS
SELECT
    osm_id,
    COALESCE("water", 'water') AS feature,
    way AS geom,
    NULL::real AS width -- osm2pgsql-gen will populate this
FROM
    public.planet_osm_polygon
WHERE
    "natural" = 'water' 
     AND (("water" = 'river' OR "water" = 'canal') 
           --OR ("water" IS NULL) AND (((ST_MaximumInscribedCircle(way)).radius))>500 
           )
    
;

CREATE INDEX ON h3.waterway_areas USING gist (geom);
CREATE INDEX ON h3.waterway_areas USING btree (osm_id);
--VACUUM ANALYZE h3.waterway_areas;


--SELECT Count(*) FROM h3.waterway_areas LIMIT 100;



