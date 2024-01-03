/*
  in this script we will prepare h3 hex grid that we are using for generalization
*/

CREATE EXTENSION IF NOT EXISTS h3;
CREATE EXTENSION IF NOT EXISTS h3_postgis CASCADE;

--DROP SCHEMA h3 CASCADE;
CREATE SCHEMA IF NOT EXISTS h3;
CREATE TABLE h3.hex
(
    ix H3INDEX NOT NULL PRIMARY KEY,
    resolution INT2 NOT NULL,
    -- v4 change: POLYGON to MULTIPOLYGON
    geom GEOMETRY (MULTIPOLYGON, 3857) NOT NULL,
    CONSTRAINT ck_resolution CHECK (resolution >= 0 AND resolution <= 15)
);
CREATE INDEX gix_h3_hex ON h3.hex USING GIST (geom);
CREATE INDEX ix_h3_hex_r ON h3.hex (resolution);      

INSERT INTO h3.hex (ix, resolution, geom)
SELECT ix, 0 AS resolution,
        -- v4 change: Wrapped in MULTI for consistent MULTIPOLYGON
        ST_Multi(ST_Transform(h3_cell_to_boundary_geometry(ix),3857)) AS geom
    FROM h3_get_res_0_cells() ix
;

INSERT INTO h3.hex (ix, resolution, geom)
SELECT h3_cell_to_children(ix) AS ix,
        resolution + 1 AS resolution,
        -- v4 change: Wrapped in MULTI for consistent MULTIPOLYGON
        ST_Multi(ST_Transform(h3_cell_to_boundary_geometry(h3_cell_to_children(ix)),3857))
            AS geom
    FROM h3.hex 
    WHERE resolution IN (SELECT MAX(resolution) FROM h3.hex);

INSERT INTO h3.hex (ix, resolution, geom)
SELECT h3_cell_to_children(ix) AS ix,
        resolution + 1 AS resolution,
        -- v4 change: Wrapped in MULTI for consistent MULTIPOLYGON
        ST_Multi(ST_Transform(h3_cell_to_boundary_geometry(h3_cell_to_children(ix)),3857))
            AS geom
    FROM h3.hex 
    WHERE resolution IN (SELECT MAX(resolution) FROM h3.hex);

INSERT INTO h3.hex (ix, resolution, geom)
SELECT h3_cell_to_children(ix) AS ix,
        resolution + 1 AS resolution,
        -- v4 change: Wrapped in MULTI for consistent MULTIPOLYGON
        ST_Multi(ST_Transform(h3_cell_to_boundary_geometry(h3_cell_to_children(ix)),3857))
            AS geom
    FROM h3.hex 
    WHERE resolution IN (SELECT MAX(resolution) FROM h3.hex);

INSERT INTO h3.hex (ix, resolution, geom)
SELECT h3_cell_to_children(ix) AS ix,
        resolution + 1 AS resolution,
        -- v4 change: Wrapped in MULTI for consistent MULTIPOLYGON
        ST_Multi(ST_Transform(h3_cell_to_boundary_geometry(h3_cell_to_children(ix)),3857))
            AS geom
    FROM h3.hex 
    WHERE resolution IN (SELECT MAX(resolution) FROM h3.hex);

INSERT INTO h3.hex (ix, resolution, geom)
SELECT h3_cell_to_children(ix) AS ix,
        resolution + 1 AS resolution,
        -- v4 change: Wrapped in MULTI for consistent MULTIPOLYGON
        ST_Multi(ST_Transform(h3_cell_to_boundary_geometry(h3_cell_to_children(ix)),3857))
            AS geom
    FROM h3.hex 
    WHERE resolution IN (SELECT MAX(resolution) FROM h3.hex);

INSERT INTO h3.hex (ix, resolution, geom)
SELECT h3_cell_to_children(ix) AS ix,
        resolution + 1 AS resolution,
        -- v4 change: Wrapped in MULTI for consistent MULTIPOLYGON
        ST_Multi(ST_Transform(h3_cell_to_boundary_geometry(h3_cell_to_children(ix)),3857))
            AS geom
    FROM h3.hex 
    WHERE resolution IN (SELECT MAX(resolution) FROM h3.hex);
    


SELECT COUNT(*), MAX(resolution) FROM h3.hex 




