#=============================================================
# This a very simple web-site engine
#
#=============================================================
from datetime import datetime


page_template ="""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%title%></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="/js/sorttable.js" type="Text/javascript"></script>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <a href="/" class="logo">OpenLandcoverMap :)</a>
        <nav class="desktop-menu">
            <a href="about.html">About</a>
            <a href="renderedtags.html">Tag Usage</a>
            <a href="country_stats.html">Country Stats</a>
            <a href="downloads.html">Downloads</a>
            <a href="empty_hex.html">Hex Inspector</a>
            <a href="https://github.com/Zkir/generalized_landcovers"><i class="fab fa-github"></i> GitHub</a>
        </nav>
        <button class="mobile-menu-btn" id="mobileMenuBtn">
            <i class="fas fa-ellipsis-v"></i>
        </button>
        <nav class="mobile-menu" id="mobileMenu">
            <a href="about.html">About</a>
            <a href="renderedtags.html">Tag Usage</a>
            <a href="country_stats.html">Country Stats</a>
            <a href="downloads.html">Downloads</a>
            <a href="empty_hex.html">Hex Inspector</a>
            <a href="https://github.com/Zkir/generalized_landcovers"><i class="fab fa-github"></i> GitHub</a>
        </nav>
    </header>

    <main>
        <%content%>
    </main>

    <footer>
        <small><%creation_timestamp%></small>
    </footer>

    <script>
        // Mobile menu functionality
        document.getElementById('mobileMenuBtn').addEventListener('click', function() {
            document.getElementById('mobileMenu').classList.toggle('active');
        });
        
        // Close mobile menu when clicking outside
        document.addEventListener('click', function(event) {
            const mobileMenu = document.getElementById('mobileMenu');
            const mobileMenuBtn = document.getElementById('mobileMenuBtn');
            
            if (mobileMenu.classList.contains('active') && 
                !mobileMenu.contains(event.target) && 
                !mobileMenuBtn.contains(event.target)) {
                mobileMenu.classList.remove('active');
            }
        });
    </script>
</body>
</html>"""

class ZWebPage:
    def __init__(self, name, title):
        self.page_name=name
        self.page_html = '' 
        self.content = '' 
        self.title = title

    def print(self, text):
        self.content += text

    def write(self):
        self.page_html = page_template.replace("<%title%>", self.title).replace("<%content%>", self.content).replace("<%creation_timestamp%>",datetime.now().strftime("%Y-%m-%d %H:%M:%S")) 

        with open('data/export/'+self.page_name, 'w', encoding="utf-8") as f1:
            f1.write(self.page_html)
