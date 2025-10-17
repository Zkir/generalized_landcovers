import psycopg2
import os
from zwebpage import ZWebPage

db_user_name = os.environ.get("PGUSER")
db_user_password = os.environ.get("PGPASSWORD")

if db_user_name is None or db_user_password is None:
    print('Error: Postgres user name or password is not set, exiting')
    print('Check PGUSER and PGPASSWORD environment variables')
    exit(1)


conn = psycopg2.connect(dbname='gis', user=db_user_name, 
                        password=db_user_password, host='localhost')
cursor = conn.cursor()

cursor.execute("SELECT * FROM h3.country_stats  ORDER BY 1 ASC;") 
records = cursor.fetchall()

cursor.close()
conn.close() 


page = ZWebPage("country_stats.html", "Landcover per country statistics")

page.print("<h2>Landcover per country statistics</h2>")
page.print("""<p>This table shows what percentage of a country's territory is covered by generalized landcovers. <br />
                     <small>The table is sortable. Just click on the column header.</small></p>
                 """)
page.print('<table class="sortable">')
page.print('<tr><th>Country or territory</th><th>Landcover % </th></tr> ')
for record in records:
    page.print(f'<tr><td>{record[0]}</td><td>{round(float(record[1])*100)}</td></tr> ')
page.print('</table>')
page.write()
