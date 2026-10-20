# Find which office6 module contains the guest-banner strings (UTF-16LE and UTF-8)
import os, glob

ROOT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6"
NEEDLES = [
    "访客状态",
    "登录激活更多功能",
    "立即登录",
    "访客模式",
]
# prioritize big core modules first
PRI = ["kshell.dll", "kso.dll", "ksolite.dll", "ksal.dll", "wps.exe", "kbase.dll", "kskin.dll"]

def utf16le(s): return s.encode("utf-16-le")
def utf8(s): return s.encode("utf-8")

files = [os.path.join(ROOT, f) for f in PRI if os.path.exists(os.path.join(ROOT, f))]
files += [p for p in glob.glob(os.path.join(ROOT, "*.dll")) if p not in files]

for path in files:
    try:
        data = open(path, "rb").read()
    except OSError:
        continue
    hits = []
    for n in NEEDLES:
        u = utf16le(n)
        a = utf8(n)
        # skip hits inside import/export name tables (rough): report raw offsets anyway
        iu = data.find(u)
        ia = data.find(a)
        hits.append((n, iu, ia))
    if any(i >= 0 for _, iu, ia in hits for i in (iu, ia)):
        print(os.path.basename(path))
        for n, iu, ia in hits:
            if iu >= 0 or ia >= 0:
                print(f"   {n}: utf16@0x{iu:X}" + (f" utf8@0x{ia:X}" if ia >= 0 else ""))
