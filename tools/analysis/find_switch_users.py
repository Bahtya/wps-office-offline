# Locate literal switch/tab names across binaries and resources
import os, re

ROOT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6"
NEEDLES = [b"CommonVipTab", b"WpsAIGCProxy", b"KxDocerFakeTabCommand", b"UseFakeTab", b"FakeTab"]
PRIO = ["ksolite.dll", "kprometheus.dll", "kshell.dll", "kso.dll", "wpsoffice.exe", "kbase.dll", "ksocial.dll"]

def rva_of(data, pat, pe_sections):
    off = data.find(pat)
    if off < 0:
        return None
    for va, vs, raw, name in pe_sections:
        if raw <= off < raw + vs:
            return off - raw + va, name
    return None, None

import pefile
for mod in PRIO + ["res\\wpsongmani.kui"]:
    p = os.path.join(ROOT, mod)
    if not os.path.exists(p):
        continue
    data = open(p, "rb").read()
    found = []
    for n in NEEDLES:
        cnt = data.count(n)
        if cnt:
            loc = ""
            if mod.endswith((".dll", ".exe")):
                try:
                    pe = pefile.PE(p, fast_load=True)
                    secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
                    r = rva_of(data, n, secs)
                    if r and r[0] is not None:
                        loc = f" firstRVA=0x{r[0]:X}({r[1]})"
                except Exception:
                    pass
            found.append(f"{n.decode()}x{cnt}{loc}")
    if found:
        print(f"{mod}: " + "; ".join(found))
