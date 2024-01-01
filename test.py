#!/usr/bin/env python
import mapnik 
mapfile = 'mapnik.xml'
map_output = 'landcovers_test_render.png'
m = mapnik.Map(1920, 1080, '+init=epsg:4326')
mapnik.load_map(m, mapfile)
bbox = mapnik.Box2d(mapnik.Coord(-14756090, -4445958), mapnik.Coord(20756090, 8445958))
m.zoom_to_box(bbox)
mapnik.render_to_file(m, map_output)


