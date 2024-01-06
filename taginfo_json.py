import psycopg2
import json
from datetime import datetime

import re

#get rendered tag list from cartocss
regex = re.compile("\[feature='(.*?)'\]")
with open("landcovers.mss") as f:
    text = f.read()
rendered_tags = [match.group(1) for match in regex.finditer(text)]


ts = datetime.now()
ts=ts.strftime("%Y%m%dT%H%M%SZ")

conn = psycopg2.connect(dbname='gis', user='test1', 
                        password='1234+', host='localhost')
cursor = conn.cursor()

cursor.execute('SELECT * from h3.landcover_tag_stats ORDER BY strength desc')
records = cursor.fetchall()
tags=[]
for record in records:
    if record[0] is not None:
        if record[1] in rendered_tags:
            description = "Rendered as landcover. Strength "+ str(record[3]) +", Total count " + str(record[4]) 
        else:
            description = "Accepted as landcover, but not rendered. Strength: "+ str(record[3]) +", Total count: " + str(record[4]) 

        tags.append({"key":record[0],
                              "value":record[1], 
                              "description": description})    

cursor.execute('SELECT * FROM h3.tag_synonyms')
records = cursor.fetchall()

for record in records:
    if record[2]=='built_up':
        description = "Considered to be a synonym of " + str(record[2]) +" for the purposes of generalization"
    else:
        description = "Considered to be a synonym of natural=" + str(record[2]) 
    tags.append({"key":record[0],
                            "value":record[1], 
                            "description": description})    

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

cursor.close()
conn.close()

print(json.dumps(taginfo_json, sort_keys=True, indent=4))


