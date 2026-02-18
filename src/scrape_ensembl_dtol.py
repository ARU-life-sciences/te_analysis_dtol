import requests
from bs4 import BeautifulSoup

URL = "https://projects.ensembl.org/darwin-tree-of-life/"

html = requests.get(URL, timeout=60).text
soup = BeautifulSoup(html, "html.parser")

links = []
for a in soup.select('a[href]'):
    href = a["href"]
    if href.endswith(".repeatmodeler.fa"):
        links.append(href)

links = sorted(set(links))
print("\n".join(links))
print(f"\nN={len(links)}")

