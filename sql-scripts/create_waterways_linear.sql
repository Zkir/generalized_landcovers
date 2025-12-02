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
		waterway AS feature,
	    ST_LineMerge(ST_Collect(way)) AS geom
	FROM
	    public.planet_osm_line
	WHERE
	    (waterway in ('river', 'canal_') /* we have to include rivers only (and exclude canals), because otherwise we will get strange cycles*/
	    OR osm_id IN ( /*some rivers have "canals" as their parts*/
	    
		    SELECT
	        	(member->>'ref')::bigint AS osm_id
	
		     FROM
		         planet_osm_rels AS rel,
		         jsonb_array_elements(rel.members) AS member
		     WHERE
		         rel.tags @> '{"type": "waterway"}'
		         AND rel.tags @> '{"waterway": "river"}'
		         AND member->>'role' = 'main_stream'
		         AND member->>'type' = 'W'
	    )
	    OR osm_id IN (1364991437)
	    )
	    --AND ST_X(ST_Centroid(way))>2000000 AND ST_Y(ST_Centroid(way))>4000000
	GROUP BY osm_id, name, waterway; /* for some mysterious reason ways are split by osm2pgsql*/   


--SELECT feature, count(feature)  FROM  h3.waterways_linear GROUP BY feature ORDER BY 2 DESC ;
--SELECT count(*) FROM h3.waterways_linear WHERE GeometryType(geom) <> 'LINESTRING';


CREATE INDEX ON h3.waterways_linear USING gist (geom);
CREATE INDEX ON h3.waterways_linear USING btree (osm_id);
--VACUUM ANALYZE h3.waterways_linear;


