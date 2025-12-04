/*
*  Source table for river generalization. 
*  We need to create subset of planet_osm_line
*/

CREATE INDEX IF NOT EXISTS waterway_planet_osm_line ON planet_osm_line("waterway");

DROP TABLE IF EXISTS h3.waterway_roles;
CREATE TABLE h3.waterway_roles AS 
SELECT
		(member->>'ref')::bigint AS osm_id,
        any_value(rel.tags ->>'name')       AS "name",
        any_value(rel.tags ->>'waterway')   AS feature,
        any_value(member->>'role')          AS role
     FROM
         planet_osm_rels AS rel,
         jsonb_array_elements(rel.members) AS member
     WHERE
         rel.tags @> '{"type": "waterway"}'
         AND rel.tags @> '{"waterway": "river"}'
         AND member->>'role' = 'main_stream'
         AND member->>'type' = 'W'
     GROUP BY member->>'ref';

CREATE INDEX ON h3.waterway_roles(osm_id);

DROP TABLE IF EXISTS h3.waterways_linear;
 
CREATE TABLE h3.waterways_linear AS
	 SELECT
	    l.osm_id,
	    l.name,
		NULL::real AS width,
		l.waterway AS feature,
        MIN(wr."role") AS "role",
	    ST_LineMerge(ST_Collect(way)) AS geom
	FROM
	    public.planet_osm_line l 
	LEFT JOIN h3.waterway_roles wr ON l.osm_id = wr.osm_id
	WHERE
    	/* we have to include rivers only (and exclude canals),
    	 *  because otherwise we will get strange cycles
    	 * */
	    (waterway in ('river', 'canal_') 
	     /*some rivers have "canals" as their parts, so we get all main streams*/
	    OR wr.osm_id IS NOT NULL
	    OR l.osm_id IN (1364991437))
	    
	    --AND ST_X(ST_Centroid(way))>2000000 AND ST_Y(ST_Centroid(way))>4000000
	/*Note, we need stricty ONE record per osm_id
	 * Typical error is that way is included into relation several times*/    
	GROUP BY l.osm_id, l.name, l.waterway; /* for some mysterious reason ways are split by osm2pgsql*/   


--SELECT feature, count(feature)  FROM  h3.waterways_linear GROUP BY feature ORDER BY 2 DESC ;
--SELECT count(*) FROM h3.waterways_linear WHERE GeometryType(geom) <> 'LINESTRING';


CREATE INDEX ON h3.waterways_linear USING gist (geom);
CREATE INDEX ON h3.waterways_linear USING btree (osm_id);
VACUUM ANALYZE h3.waterways_linear;


	
