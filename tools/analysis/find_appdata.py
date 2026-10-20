# Search APPDATA Kingsoft for the tab strings and kuip caches
import os

ROOTS = [
    r"C:\Users\1531\AppData\Roaming\Kingsoft",
    r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\_quarantine",  # skip
]
SCAN = [r"C:\Users\1531\AppData\Roaming\Kingsoft"]
NEEDLES = {
    "会员专享": "会员专享".encode("utf-16-le"),
    "会员专享utf8": "会员专享".encode("utf-8"),
    "稻壳AI模板": "稻壳AI模板".encode("utf-16-le"),
    "稻壳utf8": "稻壳".encode("utf-8"),
}
hits = {}
n = 0
for root in SCAN:
    for dirpath, dirs, files in os.walk(root):
        for fn in files:
            p = os.path.join(dirpath, fn)
            try:
                if os.path.getsize(p) > 100 * 1024 * 1024:
                    continue
                data = open(p, "rb").read()
            except OSError:
                continue
            n += 1
            for label, pat in NEEDLES.items():
                if pat in data:
                    hits.setdefault(os.path.relpath(p, root), set()).add(label)
print(f"scanned {n} files")
for k in sorted(hits):
    print(k, sorted(hits[k]))
