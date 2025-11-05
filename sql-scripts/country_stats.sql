SET statement_timeout = 0;

/*
CREATE TABLE h3.country_polygons AS 
    SELECT osm_id, "name", tags->'name:en' AS name_en, tags->'ISO3166-1' as ISO3166, admin_level, tags, way AS geom 
        FROM planet_osm_polygon 
        WHERE boundary='administrative' AND admin_level='2' AND tags->'ISO3166-1' IS NOT NULL;
*/        
        
--SELECT * FROM   h3.ne_10m_admin_0_countries ORDER BY admin;      

/* ------------------------------------------------------------------------------
 *  h3.country_polygons: just country polygons in the proper coordinate system
 * ------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS h3.country_polygons;
CREATE TABLE h3.country_polygons AS         
    SELECT 
        name_en AS name_en, adm0_a3 AS ISO3166,
        --sovereignt AS name_en, sov_a3 AS ISO3166,
        "type" AS status,
        ST_Transform(wkb_geometry,3857) AS geom
        FROM h3.ne_10m_admin_0_countries
        ORDER BY name_en;        

CREATE INDEX ix_country_polygons  ON h3.country_polygons (name_en);
CREATE INDEX gix_country_polygons ON h3.country_polygons USING GIST (geom);

/*------------------------------------------------------------------------------
 * h3.no_landcover_per_country
 * Note that we cannot just assign coutry id to the hex, 
 * because hex can belong to several countries (country borders are not hex borders)
 *  we will use it for EMPTY HEX INSPECTOR feature
 * ------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS h3.no_landcover_per_country;
CREATE TABLE h3.no_landcover_per_country AS
    SELECT
      n.ix AS ix,    
      n.geom AS geom,
      c.name_en AS country_name
    FROM
      h3.no_landcover n
      JOIN h3.country_polygons c ON ST_Intersects (n.geom, c.geom);

CREATE INDEX ix_no_landcover_per_country  ON h3.country_polygons (ix, country_name);

/*------------------------------------------------------------------------------
 *  h3.country_stats
 *  landcover statistics per country
 * ------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS h3.country_stats;
CREATE TABLE h3.country_stats AS
    SELECT
      cp.name_en,
      COALESCE(th.total_hexes, 0) AS total_hexes,
      COALESCE(eh.empty_hexes, 0) AS empty_hexes,
      COALESCE(cov.pcover, 0) AS pcover
    FROM
      h3.country_polygons cp
      LEFT JOIN (
            SELECT
              c.name_en,
              count(h.ix) AS total_hexes
            FROM
              h3.hex_land h
              JOIN h3.country_polygons c ON ST_Intersects (h.geom, c.geom)
            GROUP BY
              c.name_en
          ) as th ON cp.name_en = th.name_en
      LEFT JOIN(
            SELECT
              n.country_name AS name_en,
              count(n.ix) AS empty_hexes
            FROM
              h3.no_landcover_per_country n
            GROUP BY
              c.country_name
          ) as eh ON cp.name_en = eh.name_en
      LEFT JOIN (
            SELECT
              countries.name_en,
              ST_AREA (ST_INTERSECTION (countries.geom, landcovers.geom)) / ST_AREA (countries.geom) AS pcover
            FROM
              (
                SELECT
                  name_en,
                  ST_UNION (geom) AS geom
                FROM
                  h3.country_polygons
                GROUP BY
                  name_en
              ) AS countries,
              (
                SELECT
                  ST_UNION (geom) AS geom
                FROM
                  h3.landcovers_aggr
              ) AS landcovers
            WHERE
              ST_INTERSECTS (countries.geom, landcovers.geom)
          ) as cov ON cp.name_en = cov.name_en;



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
