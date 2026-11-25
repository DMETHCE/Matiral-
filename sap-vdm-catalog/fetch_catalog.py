"""Download the released CDS view catalog from api.sap.com.

usage: python fetch_catalog.py [OUT_DIR] [--edition PCE|CLOUD|ALL] [--only VIEW,VIEW]
"""
import argparse
import concurrent.futures as cf
import json
import os
import re
import sys
import time
import urllib.request

BASE = "https://api.sap.com/odata/1.0/catalog.svc/CdsViewsContent.CdsViews"


def http_json(url, tries=4):
    for i in range(tries):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception:
            if i == tries - 1:
                raise
            time.sleep(2 * (i + 1))


def list_views():
    out, skip = [], 0
    while True:
        url = f"{BASE}?$format=json&$select=TechnicalName,Description,DisplayName,State&$top=1000&$skip={skip}"
        res = http_json(url)["d"]["results"]
        out += res
        if len(res) < 1000:
            return out
        skip += 1000


def clean(txt):
    txt = re.sub(r"<[^>]+>", " ", txt or "")
    return re.sub(r"\s+", " ", txt).strip()


def tables_in(desc):
    found = re.findall(r"\b(?:database )?tables?\s+\(?([A-Z][A-Z0-9_/]{2,29}(?:\s*(?:,|and|/)\s*[A-Z][A-Z0-9_/]{2,29})*)", desc)
    names = set()
    for grp in found:
        for n in re.split(r"\s*(?:,|and|/)\s*", grp):
            if n.isupper() and len(n) >= 3:
                names.add(n)
    return sorted(names)


def fetch_view(tech):
    j = http_json(f"{BASE}('{tech}')/$value")
    desc = clean(j.get("short_description"))
    return {
        "tech": tech,
        "edition": "PCE" if tech.startswith("PCE_") else ("OP" if tech.startswith("OP_") else "CLOUD"),
        "name": j.get("cdsview_name", ""),
        "title": j.get("cdsview_title", ""),
        "category": j.get("category", ""),
        "status": j.get("status", ""),
        "component": j.get("application_component", ""),
        "lob": j.get("LoB", ""),
        "text_view": j.get("related_text_view_id", ""),
        "successors": ",".join(s.get("successorname", "") if isinstance(s, dict) else str(s) for s in j.get("successors") or []),
        "tables": ",".join(tables_in(desc)),
        "desc": desc[:400],
        "fields": [
            [f.get("fieldname", ""), f.get("description", ""), f.get("datatype", ""),
             str(int(f.get("fieldlength") or 0)), f.get("field_state", ""), f.get("successor", "")]
            for f in j.get("fields") or []
        ],
    }


def tsv(v):
    return str(v).replace("\t", " ").replace("\n", " ").replace("\r", " ")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", nargs="?", default=os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--edition", default="PCE", choices=["PCE", "CLOUD", "ALL"])
    ap.add_argument("--only", default="")
    ap.add_argument("--workers", type=int, default=16)
    a = ap.parse_args()

    # select views
    views = list_views()
    if a.only:
        want = {v.strip().upper() for v in a.only.split(",")}
        techs = [v["TechnicalName"] for v in views
                 if v["TechnicalName"] in want or v["TechnicalName"].removeprefix("PCE_") in want]
    else:
        def keep(t):
            if a.edition == "PCE":
                return t.startswith("PCE_")
            if a.edition == "CLOUD":
                return not t.startswith(("PCE_", "OP_"))
            return True
        techs = [v["TechnicalName"] for v in views if keep(v["TechnicalName"])]
    print(f"{len(techs)} views", file=sys.stderr)

    # fetch details
    rows, errors = [], []
    with cf.ThreadPoolExecutor(a.workers) as ex:
        futs = {ex.submit(fetch_view, t): t for t in techs}
        for i, f in enumerate(cf.as_completed(futs), 1):
            try:
                rows.append(f.result())
            except Exception as e:
                errors.append(f"{futs[f]}\t{e}")
            if i % 500 == 0:
                print(f"  {i}/{len(techs)}", file=sys.stderr)
    rows.sort(key=lambda r: r["name"].upper())

    # write files
    suffix = "" if not a.only else "_partial"
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, f"views{suffix}.tsv"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("view\tedition\tcategory\tstatus\ttitle\ttext_view\tdb_tables\tcomponent\tsuccessors\tdescription\n")
        for r in rows:
            fh.write("\t".join(tsv(r[k]) for k in ("name", "edition", "category", "status", "title", "text_view",
                                                    "tables", "component", "successors", "desc")) + "\n")
    with open(os.path.join(a.out, f"fields{suffix}.tsv"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("view\tfield\tdescription\ttype\tlength\tfield_state\tsuccessor\n")
        for r in rows:
            for f in r["fields"]:
                fh.write(tsv(r["name"]) + "\t" + "\t".join(tsv(x) for x in f) + "\n")
    if errors:
        with open(os.path.join(a.out, "errors.log"), "w", encoding="utf-8") as fh:
            fh.write("\n".join(errors) + "\n")
    print(f"done: {len(rows)} views, {len(errors)} errors", file=sys.stderr)


if __name__ == "__main__":
    main()
