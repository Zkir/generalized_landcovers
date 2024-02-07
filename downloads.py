import os
from datetime import datetime
from zwebpage import ZWebPage
import psycopg2

LOCAL_PATH="data/export/downloads"
WEB_PATH="downloads"

LANDCOVERS_ZIP = "landcovers.zip"
PEAKS_ZIP = "peaks.zip"
PLACES_ZIP= "places.zip"

files=[[LANDCOVERS_ZIP,"Generalized landcovers polygons in shape format"],
         [PEAKS_ZIP," Mountain peak points with cartographic importance calculated  <br />using the Discrete Isolation method."],
         [PLACES_ZIP,"City and town points with cartographic importance calculated <br />using the Grid Cell method."] ]


db_user_name = os.environ.get("PGUSER")
db_user_password = os.environ.get("PGPASSWORD")

if db_user_name is None or db_user_password is None:
    print('Error: Postgres user name or password is not set, exiting')
    print('Check PGUSER and PGPASSWORD environment variables')
    exit(1)

conn = psycopg2.connect(dbname='gis', user=db_user_name,
                        password=db_user_password, host='localhost')
cursor = conn.cursor()
cursor.execute("select value as last_known_edit  from osm2pgsql_properties where property='current_timestamp';" )
records = cursor.fetchall()
last_known_edit=str(records[0][0])


page = ZWebPage("downloads.html", "OpenLandcoverMap Downloads")
page.print("""<h1>OpenLandcoverMap downloads</h1>
    <table class="sortable" >
    <tr>
    <th>File</th>
    <th>Description</th>
    <th> Update date </th>
    <th>Last known edit</th>
    </tr>""" )

for file in files:
    s =''
    s+='<tr>'
    s+='  <td>'
    s+='     <a href="'+WEB_PATH+'/'+file[0]+'">'+ file[0]+ '</a>'
    s+='  </td>'
    s+='  <td>'
    s+=     file[1]
    s+='  </td>'
    s+='  <td> '
    s+=   datetime.fromtimestamp(os.path.getmtime(LOCAL_PATH+'/'+file[0])).strftime('%Y-%m-%d')
    s+='  </td>'
    s+='  <td>'+last_known_edit+'</td>'

    s+='</tr>'
    page.print(s)

page.print('</table>')

page.write()
