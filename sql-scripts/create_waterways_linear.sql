/*
*  Source table for river generalization. 
*  We need to create subset of planet_osm_line
*/

CREATE INDEX IF NOT EXISTS waterway_planet_osm_line ON planet_osm_line("waterway");

DROP TABLE IF EXISTS h3.waterways_linear;

CREATE TABLE h3.waterways_linear AS
SELECT
    osm_id,
    name,
	NULL::real AS width,
    way as geom
FROM
    public.planet_osm_line
WHERE
    waterway in ('river', 'canal');

CREATE INDEX ON h3.waterways_linear USING gist (geom);
CREATE INDEX ON h3.waterways_linear USING btree (osm_id);
VACUUM ANALYZE h3.waterways_linear;


