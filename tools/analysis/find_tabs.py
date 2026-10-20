# Search all office6 files for the three tab labels (utf-8/utf-16 raw + zlib-decompressed rcc)
import os, zlib

ROOT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6"
NEEDLES = {
    "会员专享": ["会员专享".encode("utf-8"), "会员专享".encode("utf-16-le")],
    "WPSAI标签": [b"WPS AI", "WPS AI".encode("utf-16-le")],
    "稻壳AI模板": ["稻壳AI模板".encode("utf-8"), "稻壳AI模板".encode("utf-16-le")],
}

hits = {}
nfiles = 0
for dirpath, dirs, files in os.walk(ROOT):
    for fn in files:
        p = os.path.join(dirpath, fn)
        try:
            sz = os.path.getsize(p)
            if sz > 200 * 1024 * 1024:
                continue
            data = open(p, "rb").read()
        except OSError:
            continue
        nfiles += 1
        rel = os.path.relpath(p, ROOT)
        for label, pats in NEEDLES.items():
            for pat in pats:
                if pat in data:
                    hits.setdefault(rel, set()).add(label)

print(f"scanned {nfiles} files")
for k in sorted(hits):
    print(k, sorted(hits[k]))
