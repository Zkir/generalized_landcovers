#!/usr/bin/env python
# ======================================================
#  we will generate taginfo.json with actual usage of tags in this project
#  based on tag transformation rules in sql-files
#  and in CartoCSS style sheets, especially landcovers.mss
#  some details on taginfo.json: 
#        https://wiki.openstreetmap.org/wiki/Taginfo/Projects
# ======================================================

import psycopg2
import json
import re
import requests
import os
from datetime import datetime

db_user_name = os.environ.get("PGUSER")
db_user_password = os.environ.get("PGPASSWORD")

if db_user_name is None or db_user_password is None:
    print('Error: Postgres user name or password is not set, exiting')
    print('Check PGUSER and PGPASSWORD environment variables')
    exit(1)

rendered_tags_html = ""
unrendered_tags_html = ""

#get rendered tag list from cartocss
regex = re.compile("\[feature='(.*?)'\]")
with open("landcovers.mss") as f:
    text = f.read()
rendered_tags = [match.group(1) for match in regex.finditer(text)]

ts = datetime.now()
ts=ts.strftime("%Y%m%dT%H%M%SZ")

conn = psycopg2.connect(dbname='gis', user=db_user_name, 
                        password=db_user_password, host='localhost')
cursor = conn.cursor()

cursor.execute('SELECT * from h3.landcover_tag_stats ORDER BY strength desc')
records = cursor.fetchall()

cursor.execute('SELECT * FROM h3.tag_synonyms')
tag_synonyms= cursor.fetchall()

cursor.close()
conn.close() 


tags=[]
for record in records:
    if record[0] is not None:
        if ' ' in record[1]:
            wiki_described=False # Tags with spaces are not valid values for landuse/natural key
            wiki_url=''
        else:
            wiki_url='https://wiki.openstreetmap.org/wiki/Tag:'+record[0]+'%3D'+record[1]
            wiki_described=requests.head(wiki_url).ok

        #print (wiki_url+ ' : '+str(wiki_described))

        if record[1] in rendered_tags:
            description = "Rendered as landcover. Strength "+ str(record[3]) +", Total count " + str(record[4]) 
        else:
            description = "Accepted as landcover, but not rendered. Strength: "+ str(record[3]) +", Total count: " + str(record[4]) 
        
        # we may exclude strange occurences from statisitics for taginfo, but we still need to report rare tags included in rendering     
        if (record[1] in rendered_tags) or (record[4]>=20) or (wiki_described and (record[4]>=4)):
            tags.append({"key":record[0],
                                  "value":record[1], 
                                  "description": description,
                                  "object_types": [ "area"]})    

    if record[1] in rendered_tags:
        #page for rendered tags

        if record[0] is not None:
            orig_tags_descr= (('<a href="'+wiki_url+'">'+record[0]+'='+record[1]+'</a>') if wiki_described else (record[0]+'='+record[1]))
        else:
            # this a 'composite' landcover, like built_up.
            orig_tags_descr=''     

        #we still need to check synonyms here.
        for tag_synonym in tag_synonyms:
            if (tag_synonym[2]==record[1]):
                wiki_url='https://wiki.openstreetmap.org/wiki/Tag:'+tag_synonym[0]+'%3D'+tag_synonym[1]
                wiki_described=requests.head(wiki_url).ok
                orig_tags_descr= orig_tags_descr+'<br />' +(('<a href="'+wiki_url+'">'+tag_synonym[0]+'='+tag_synonym[1]+'</a>') if wiki_described else (tag_synonym[0]+'='+tag_synonym[1]))

        rendered_tags_html = rendered_tags_html + '<tr>' + \
                                                 '<td>' +record[1]+ '</td>' + \
                                                 '<td>'+ orig_tags_descr +'</td>'+ \
                                                 ' <td>'+str(record[3])+'</td>'+ \
                                                 ' <td>'+str(record[4])+'</td></tr>'
    else:
        #page for not rendered tags
        if record[4]>=4:
            unrendered_tags_html = unrendered_tags_html + '<tr>'+ \
                                                 '<td>' +record[1]+ '</td>'+ \
                                                 '<td>'+('&#10004' if wiki_described else '')+ ' </td>'   + \
                                                 '<td>'+(('<a href="'+wiki_url+'">'+record[0]+'='+record[1]+'</a>') if wiki_described else (record[0]+'='+record[1])) +'</td>'+ \
                                                 ' <td>'+str(record[3])+'</td>'+ \
                                                 ' <td>'+str(record[4])+'</td></tr>'


for record in tag_synonyms:
    if record[2]=='built_up':
        description = "Considered to be a synonym of " + str(record[2]) +" for the purposes of generalization"
    else:
        description = "Considered to be a synonym of natural=" + str(record[2]) 
    tags.append({"key":record[0],
                            "value":record[1], 
                            "description": description,
                            "object_types": ["area"]})      

taginfo_json={
       "data_format": 1,           # data format version, currently always 1, will get updated if there are incompatible changes to the format (required)
       # "data_url": "...",          # this should be the URL under which this project file can be accessed (optional)
       "data_updated": str(ts), #  "yyyymmddThhmmssZ", # timestamp when project file was updated (optional, will use HTTP header date if not available)
       "project": {                # meta information about the project (required)
           "name": "OpenLandcoverMap ;)",          # name of the project (required)
           "description": "OSM-based map of Earth land covers",   # short description of the project (required)
           "project_url": "https://github.com/Zkir/generalized_landcovers",   # home page of the project with general information (required)
           #"doc_url": "...",       # documentation of the project and especially the tags used (optional)
           #"icon_url": "...",      # project logo, should work in 16x16 pixels on white and light gray backgrounds (optional)
           "contact_name": "Kirill B. aka Zkir",  # contact name, needed for taginfo maintainer (required)
           "contact_email": "zkir@zkir.ru"  # contact email, needed for taginfo maintainer (required)
       },
       "tags": tags               # list of keys and tags used (see below)
 }



with open('taginfo.json', 'w') as f:
    f.write(json.dumps(taginfo_json, sort_keys=True, indent=4))


rendered_tags_html='<html>' \
                                  + '<head> <script src="/js/sorttable.js" type="Text/javascript"></script>' \
                                  + '<style>' \
                                  + 'table {border: 1px solid grey;} ' \
                                  + 'th {border: 1px solid grey; }' \
                                  + 'td {border: 1px solid grey; padding:5px}' \
                                  + '</style></head>' \
                                  + '<body><h2>Rendered Landcovers</h2>' \
                                  + '<p>Those landcovers are rendered with own colour/pattern. </p>' \
                                  + '<table class="sortable">'  \
                                  + '<tr><th>Landcover</th> <th>Original OSM tags</th> <th>Size Score</th> <th>Area Score</th></tr>'  \
                                  + rendered_tags_html + '</table>' \
                                  + '<h2>Not rendered Landcovers</h2>' \
                                  + '<p>Those landcovers are strong enough to appear on the generalized map but are rendered in black. <p>' \
                                  + '<table class="sortable">' \
                                  + '<tr><th>Landcover</th><th>wiki described </th> <th>Original OSM tags</th> <th>Size Score</th> <th>Area Score</th></tr>'  \
                                  +unrendered_tags_html + '</table></body></html>'

#                                + '</body></html>'
#unrendered_tags_html='<html><body>' \

with open('data/export/renderedtags.html', 'w') as f1:
    f1.write(rendered_tags_html)

# with open('unrenderedtags.html', 'w') as f2:
#    f2.write(unrendered_tags_html)