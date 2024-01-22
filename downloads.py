import os
from datetime import datetime


LOCAL_PATH="data/export/downloads"
WEB_PATH="downloads"

LANDCOVERS_ZIP = "landcovers.zip"
PEAKS_ZIP = "peaks.zip"
PLACES_ZIP= "places.zip"

files=[[LANDCOVERS_ZIP,"Generalized landcovers polygons in shape format"],
         [PEAKS_ZIP," Mountain peak points with cartographic importance calculated  <br />using the Discrete Isolation method."],
         [PLACES_ZIP,"City and town points with cartographic importance calculated <br />using the Grid Cell method."] ]



s = """<html>
<head>
  <title>OpenLandcoverMap downloads</title>
  <script src="/js/sorttable.js" type="Text/javascript"> </script>
  <style>
    table {border: 1px solid grey;}
    th {border: 1px solid grey; }
    td {border: 1px solid grey; padding:5px}
  </style>
</head>
<body>
<h1>OpenLandcoverMap downloads</h1>
<table class="sortable" >
<tr>
  <th> File  </th>
  <th> Description </th>
  <th> Update date </th>
</tr>""" 

for file in files:
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
    s+='</tr>'

s += '</table>'
s += '<hr />'
s +=  '<small><center> page created '+datetime.now().strftime("%Y-%m-%d %H:%M:%S")+'</center></small>'
s += """
</body>
</html>"""

with open('data/export/downloads.html', 'w') as f1:
    f1.write(s)
