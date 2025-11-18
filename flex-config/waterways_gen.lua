-- This file defines the generalization strategy for waterways (rivers)
-- to be used with the osm2pgsql-gen binary.

-- Create the destination table first, because osm2pgsql-gen expects it to exist.
osm2pgsql.run_sql({
    description = "Create rivers_gen destination table",
    sql = [[
        DROP TABLE IF EXISTS h3.rivers_gen;
        CREATE TABLE h3.rivers_gen (
            osm_id int8,
            width real,
            name text,
            geom geometry(Geometry, 3857)
        );
    ]]
})

-- Call the built-in 'rivers' generalization strategy.
osm2pgsql.run_gen("rivers", {
    name = "River Network Generalizer",
    -- Parameters for the 'rivers' strategy
    -- These should correspond to the parameters used by gen_rivers_t
    -- as seen in gen-rivers.cpp.
    schema = "h3",
    src_table = "waterways_linear", 
    src_areas = "waterway_areas",
    -- The geom_column is typically 'way' for line geometries.
    geom_column = "geom",    
    -- osm_id is the standard column for OSM IDs.
    id_column = "osm_id",   
    -- name is the standard column for names.
    name_column = "name",   
    -- width column will be calculated/propagated by gen-rivers logic.
    width_column = "width", 
    -- The destination table for the generalized rivers.
    dest_table = "rivers_gen"  
})