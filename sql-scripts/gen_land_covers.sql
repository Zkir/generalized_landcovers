SET statement_timeout = 0;
/*
drop TABLE IF EXISTS h3.landcovers;
drop table IF EXISTS h3.landcovers_clipped ;
drop table IF EXISTS h3.hex_features_stats;
drop table IF EXISTS h3.landcovers_h3;
DROP TABLE IF EXISTS h3.landcovers_aggr;
DROP TABLE IF EXISTS h3.landcovers_aggr_m; 
drop table IF EXISTS h3.landcover_quality;
drop table IF EXISTS h3.landcover_quality2;  
drop table IF EXISTS h3.landcover_quality3;  
*/

/*
   select landcover from OSM data, naturals and landuses.
   we select ALL naturals and landuses regardless of their area.
*/
CREATE TABLE h3.landcovers AS
    SELECT * 
        FROM (
            SELECT 
              osm_id,
              COALESCE("natural",landuse) AS feature,
              way AS geom
              FROM planet_osm_polygon
              where (planet_osm_polygon.landuse IS NOT NULL OR planet_osm_polygon."natural" IS NOT NULL)
                      ) AS t
        WHERE 
          /*some normal and documented features have to be skipped, because they are not really landcovers  */
            feature NOT IN (
                /*
                  first of all some natural geography 
                */
                'region', 'peninsula', 'cape', 'flat', 'valley', 'plain',
                'sea','isthmus', 'strait', 'gulf', 'bay', 'coastline',
                'islet','island','atoll','archipelago',
                'plateau','mesa',  
                'massif', 'mountain', 'mountain_range', 'mountains', 'hill','peak','saddle','ridge', 'cliff', 
                'volcano', 'crater', 'caldera', 'crater_rim', 'sinkhole', 'gorge', 
                
                /* natural=oasis is rather geographical feature, with other actual landcovers */
                'oasis',
                
                /*
                  Standalone features
                */
                'tree', /* natural=tree is standalone tree, not a landcover like natural=wood */
                'stone', 'rock', /* rock, stone  -- is just a single notable rock/stone, not a landcover like 'blockfield.*/ 
                'shrub', /* unclike scrub, natural=shrub is just a single plant!*/ 

                /*
                  various types of natural reserves, that can be anything
                */
                'conservation', 'national_reserve', 'natural_reserve', 'nature_reserve',
                
                /* landuse=recreation_ground is used in USA rather as natural park or natural reserve */
                'recreation_ground',
                
                /* 
                   landuse=winter_sports is significant feature, but it does not imply any landcover type, 
                   and should not screen features like wood, ice, glacier etc
               */
                'winter_sports',
                    
                /* 
                  other landuses that does not mean any specific land cover
                */
                'military', 'protected_area', 'reservoir_watershed',
                
                /* especially wasteland. area is not just used for anything! but it does not imply any landcover*/
                'wasteland',
                  
                /* landuse=religious does not imply any landcover type. In Europe it is usually build up (e.g. monastery), but it can be a sacred orchard as well. */
                'religious',  
                
                /*  natural=reef is underwater feature, not a landcover. */
                'reef',
                
                /*  natural=shoal is rather an  underwater feature */
               'shoal', 
                
                /*  landuse=aquaculture is water feature, not a landcover. */
                'aquaculture',
                
                /* natural=landform is unfortunate canadian import with a very strange tagging scheme, we cannot do much with it. */
                'landform',
 
                /* natural=riverbed is depricated due to unclear semantics*/                 
                'riverbed',

                /* natural=floodplain is an inactive proposal. Does not impose any landcover. */
                'floodplain',

                /* natural=drainage_divide is not a land cover and is rather a linear tag  */
                'drainage_divide',

                /* natural=land is deprecated, used to map islands */                 
                'land',
                
                /* landuse=farm and landuse=field are deprecated, let's ignore them*/
                'farm', 'field', 'agriculture', 'agricultural', 'pasture',
                
                /* landuse=forestry is a strange tag. it's neither forest not clearcut nor logging nor parking etc.*/
                'forestry'
                )
     
         
            /* 
              some strange features, not described on wiki
            */
            AND feature NOT IN (
                'old_coastline',
                'fishing_bank',
                'resource_extraction',
                'epicentre', /* natural=epicenter is not event proposed feature*/
                'objectiv',
                'project',
                'survey_area',
                'high-water',
                'not_meadow',
                'proposed',
                'yes',
                'orchard abandon',
                'property'
                )

            /*common mistypes*/
            AND feature NOT IN (
                'Peninsula',
                'peninsular',
                'moutain_range');

CREATE INDEX gix_h3_landcovers ON h3.landcovers USING GIST (geom);
CREATE INDEX feat_h3_landcovers ON h3.landcovers(feature);
--Drop  INDEX feat_h3_landcovers ;

     
/*
  Perform some normalizaiton
*/


-- drop table h3.tag_synonyms
CREATE TABLE h3.tag_synonyms(
    "key" TEXT,
    "tag" TEXT PRIMARY KEY,
    "feature" TEXT
);

INSERT INTO h3.tag_synonyms ("key", "tag", "feature")
VALUES 
	('landuse', 'forest', 'wood'),   --landuse=forest is a synonym for natural=wood 
    ('natural', 'woodland', 'wood'),
    ('landuse', 'basin', 'water'),  -- landuse=basin is a synonym for natural=water + water=basin
    ('landuse', 'reservoir', 'water'), --landuse=reservoir is a [deprecated] synonym of natural=water + water=reservoir
    ('natural', 'bedrock', 'bare_rock'), /* natural=bedrock is deprecated synonim of  natural=bare_rock */
    ('natural', 'lava', 'bare_rock'), /* natural=lava is a strange tag, can be considered as a synonim of  natural=bare_rock*/
    ('natural', 'dune', 'sand'),  /*  dune, dunes -->sand.   Arguable: according to wiki, dunes should be subtracted(!) from the sands. */
    ('natural', 'dunes', 'sand'),
    ('natural', 'shrubbery', 'scrub'),  
    ('natural', 'naled', 'glacier'),  
    ('natural', 'ice', 'glacier'),  
    ('natural', 'ground', 'bare_earth'),  
    ('natural', 'dry_lake', 'desert'),  
    ('landuse', 'grass', 'grassland'),  /*  landuse=grass should be considered to be a synonim of grassland for the purposes of generalization. There are no lawns kilomers long! */
    ('landuse', 'animal_keeping', 'farmyard'),  
    ('landuse', 'residential', 'built_up'), /*built up areas has to be groupped*/
    ('landuse', 'industrial', 'built_up'),
    ('landuse', 'harbour', 'built_up'),
    ('landuse', 'commercial', 'built_up'),
    ('landuse', 'education', 'built_up'),
    ('landuse', 'institutional', 'built_up'),
    ('landuse', 'civic_admin', 'built_up'),
    ('landuse', 'retail', 'built_up'),
    ('landuse', 'garages', 'built_up'),
    ('landuse', 'greenfield', 'built_up'),
    ('landuse', 'construction','built_up'),
    ('landuse', 'brownfield','built_up'),
    ('landuse', 'village_green','built_up')    
    ;


UPDATE h3.landcovers t1
    SET feature =  t2.feature
    FROM h3.tag_synonyms  t2
    WHERE t1.feature = t2.tag;


/*
  Also note that we have to replace synonyms first, and only then delete waterbodies, because some features may become water after synonim resolution
  variant without water, because in some areas only lakes are mapped, and it creates seas, which is not really desirable
*/
DELETE FROM h3.landcovers WHERE feature='water';


/*
  Clip landcover polygons by hexes, 
  currently resolution 6
*/
CREATE TABLE h3.landcovers_clipped AS
    SELECT 
       h3.landcovers.osm_id,
       h3.hex.ix,
       h3.landcovers.feature,
       ST_Area(h3.landcovers.geom) AS orig_area,
       ST_Multi(
            ST_Buffer(
                st_intersection(h3.hex.geom, h3.landcovers.geom),
                0.0
            )
        ) as clipped_geom
       from h3.hex
          inner join h3.landcovers ON ST_Intersects(h3.hex.geom, h3.landcovers.geom)
       where not ST_IsEmpty(ST_Buffer(ST_Intersection(h3.hex.geom, h3.landcovers.geom), 0.0))
          AND h3.hex.resolution=6;

CREATE INDEX ix_h3_landcovers_clipped ON h3.landcovers_clipped (ix);   
      
/* 
  Calculate hex statistics, grouped both by hex and feature. 
  We need it for proper aggregation 
*/
CREATE TABLE h3.hex_features_stats AS
    SELECT g1.*, st_area(geom) AS hex_area, srid_area/st_area(geom) AS area_rate, geom 
        FROM ( 
            SELECT ix, feature, COUNT(1), SUM(st_area(clipped_geom)) AS srid_area 
              FROM  h3.landcovers_clipped  
              GROUP BY ix, feature
            ) g1
        INNER JOIN h3.hex ON h3.hex.ix = g1.ix
      ;

/*
  Apply  thresholds. 
  there are different tresholds rates for built_up areas and all others.
  Reason: significant part of a hex should be occupied by built up areas, to be considered to be built_up.
  otherwise in the poorly mapped areas we get great metropolitain areas, which is not expected.
*/
Delete   FROM h3.hex_features_stats WHERE (feature='built_up' and area_rate<0.1) OR (feature<>'built_up' and area_rate<0.01);

CREATE INDEX ix_h3_hex_features_stats ON h3.hex_features_stats (ix); 
 
/*
  Now geospatial magic: actually do generalization.
  we determine dominating landcover type for each hex
*/  

CREATE TABLE h3.landcovers_h3 AS                             
    SELECT 
        cast(g1.ix AS VARCHAR(16)),
        g1.feature,
        g1.srid_area,
        g1.hex_area,
        g1.area_rate,
        g1.geom
    
    FROM h3.hex_features_stats g1
    INNER JOIN (
      SELECT ix, MAX( srid_area ) srid_area
      FROM h3.hex_features_stats
      GROUP BY ix ) g2
      ON g1.ix = g2.ix AND g1.srid_area = g2.srid_area;



--SELECT COUNT (1), 1950243 FROM landcovers_h3 ;

/* 
  One more magic: adjucent hexes with the same feature are united into the new generalized geometry
  create generalized polygons
*/
CREATE TABLE h3.landcovers_aggr_m AS
    SELECT feature,
            ST_Multi((ST_Union(f.geom))) as geom
    
         FROM h3.landcovers_h3 As f
         WHERE area_rate >=0.01
    GROUP BY feature;

-- for some reason we need to "dump" them
CREATE TABLE h3.landcovers_aggr AS
    SELECT feature,  (ST_dump(geom)).geom AS geom 
        FROM h3.landcovers_aggr_m;
    
    

