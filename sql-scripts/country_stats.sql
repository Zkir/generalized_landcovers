SET statement_timeout = 0;

-- drop table if exists h3.country_polygons;
-- drop table if exists h3.country_stats;
-- drop table if exists h3.country_stats2;

/*
CREATE TABLE h3.country_polygons AS 
    SELECT osm_id, "name", tags->'name:en' AS name_en, tags->'ISO3166-1' as ISO3166, admin_level, tags, way AS geom 
        FROM planet_osm_polygon 
        WHERE boundary='administrative' AND admin_level='2' AND tags->'ISO3166-1' IS NOT NULL;
*/        
        
--SELECT * FROM   h3.ne_10m_admin_0_countries ORDER BY admin;      

CREATE TABLE h3.country_polygons AS         
    SELECT 
        name_en AS name_en, adm0_a3 AS ISO3166,
        --sovereignt AS name_en, sov_a3 AS ISO3166,
        "type" AS status,
        ST_Transform(wkb_geometry,3857) AS geom
        FROM h3.ne_10m_admin_0_countries
        ORDER BY name_en;        
        
--SELECT * FROM    h3.country_polygons ORDER BY status;      
        

CREATE TABLE h3.country_stats AS 
    SELECT countries.name_en, ST_AREA(ST_INTERSECTION(countries.geom, landcovers.geom)) / ST_AREA(countries.geom) as pcover, countries.geom --ST_INTERSECTION(foo.geom, bar.geom) AS geom, bar.feature
    FROM (
            SELECT name_en, ST_UNION(geom) as geom
            FROM h3.country_polygons
            GROUP BY name_en
         ) as countries, (
            SELECT ST_UNION(geom) as geom
            FROM h3.landcovers_aggr
         ) as landcovers
    WHERE ST_INTERSECTS(countries.geom, landcovers.geom) ;


-- SELECT * FROM h3.country_stats  ORDER BY 2 DESC;

/*
CREATE TABLE h3.country_stats2 AS 
    SELECT countries.name_en, ST_AREA(ST_INTERSECTION(countries.geom, landcovers.geom)) / ST_AREA(countries.geom) as pcover, countries.geom --ST_INTERSECTION(foo.geom, bar.geom) AS geom, bar.feature
    FROM (
            SELECT name_en, ST_UNION(geom) as geom
            FROM h3.country_polygons
            GROUP BY name_en
         ) as countries, (
            SELECT ST_UNION(geom) as geom
            FROM h3.landcovers
         ) as landcovers
    WHERE ST_INTERSECTS(countries.geom, landcovers.geom) ;
*/

--SELECT * from  h3.country_stats2 
