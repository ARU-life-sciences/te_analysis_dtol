#!/usr/bin/env python3
import time
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

BASE = "https://ftp.ebi.ac.uk/pub/databases/ensembl/repeats/unfiltered_repeatmodeler/species/"

session = requests.Session()
session.headers["User-Agent"] = "repeatmodeler-link-scraper/1.0"


def get_links(url: str):
    r = session.get(url, timeout=60)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    return [urljoin(url, a.get("href")) for a in soup.select("a[href]")]


def main():
    # 1) list species directories
    links = get_links(BASE)
    species_dirs = [
        u for u in links if u.endswith("/") and u != BASE and not u.endswith("../")
    ]

    out = []
    for i, sp in enumerate(species_dirs, 1):
        print(f"Processing {i}/{len(species_dirs)}: {sp}")
        # be polite
        if i % 50 == 0:
            time.sleep(0.5)

        sublinks = get_links(sp)
        fa = [u for u in sublinks if u.endswith(".repeatmodeler.fa")]

        # usually one, but keep it general
        sp_name = sp.rstrip("/").split("/")[-1]
        for u in fa:
            out.append((sp_name, u))

    # write TSV
    with open("repeatmodeler_links.tsv", "w") as f:
        f.write("species_dir\turl\n")
        for sp, u in out:
            f.write(f"{sp}\t{u}\n")

    print(f"Wrote {len(out)} links to repeatmodeler_links.tsv")


if __name__ == "__main__":
    main()
