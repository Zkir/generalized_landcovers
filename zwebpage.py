#=============================================================
# This a very simple web-site engine
#
#=============================================================
from datetime import datetime

class ZWebPage:
    def __init__(self, name, title):
        self.page_name=name
        self.page_html = '' 
        self.content = '' 
        self.title = title

    def print(self, text):
        self.content += text

    def write(self):
        self.page_html = '<html>' \
                                  + '<head>' \
                                  + '<meta charset="UTF-8">' \
                                  + '<title>' + self.title + '</title>' \
                                  +'<script src="/js/sorttable.js" type="Text/javascript"></script>' \
                                  + '<style>' \
                                  + 'table {border: 1px solid grey;} ' \
                                  + 'th {border: 1px solid grey; }' \
                                  + 'td {border: 1px solid grey; padding:5px}' \
                                  + '</style>' \
                                  + '</head>' \
                                  + '<body>'

        self.page_html += """<div id=menu>
                  <b><a href="/">OpenLandcoverMap :)</a> </b> -- <a href="renderedtags.html">Tag usage</a> 
                  -- <a href="downloads.html">Downloads</a> 
                  -- <a href="https://github.com/Zkir/generalized_landcovers">GitHub</a>
               </div>"""

        self.page_html += self.content

        self.page_html += '<hr />' \
                                   + '<small><center> page created '+datetime.now().strftime("%Y-%m-%d %H:%M:%S")+'</center></small>' \
                                   + '</body></html>'

        with open('data/export/'+self.page_name, 'w', encoding="utf-8") as f1:
            f1.write(self.page_html)
