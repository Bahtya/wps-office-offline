# Analyze ksomisc.exe: find how checkbox settings map to registry/config writes
import re, struct, pefile

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksomisc.exe"
data = open(DLL, 'rb').read()
pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def off2rva(off):
    for va, vs, raw, name in secs:
        if raw <= off < raw + vs: return off - raw + va

print("=== sections ===")
for va, vs, raw, name in secs:
    print(f"  {name}: VA 0x{va:X} size 0x{vs:X} raw 0x{raw:X}")

# 1. Search for the known checkbox label strings (they're Qt translated, so look for
#    the English source strings that map to the Chinese labels)
# Known settings from 功能定制 page:
#   - HideWPSAiMenu -> 关闭场景化功能推荐 etc
# Search for setting-related identifiers
print("\n=== kic/switch/config identifiers ===")
seen = set()
for kw in [rb'kic[/\\]switch', rb'compatible_type', rb'HideNewFromTemplate',
           rb'DisableOfficeNav', rb'CloseTemplate', rb'CloseOnline',
           rb'CloseScene', rb'HideWPS[A-Za-z]+', rb'AutoUpgrade',
           rb'CloseAutoUpgrade', rb'NoUpgrade']:
    for m in re.finditer(kw, data):
        b = m.start()
        # get full string
        e = b
        while e < len(data) and 32 <= data[e] < 127: e += 1
        b2 = b
        while b2 > 0 and 32 <= data[b2-1] < 127: b2 -= 1
        st = data[b2:e].decode('ascii','replace')
        if st not in seen and len(st) < 100:
            seen.add(st)
            rva = off2rva(b2)
            print(f"  @0x{rva:X}: {st[:80]}")

# 2. Find the checkbox config names (English source strings for the Chinese labels)
print("\n=== checkbox English source strings ===")
seen2 = set()
for kw in [rb'[Cc]lose[A-Z][a-z]', rb'[Hh]ide[A-Z][a-z]', rb'[Dd]isable[A-Z][a-z]']:
    for m in re.finditer(kw + rb'[A-Za-z]{3,30}', data):
        s = m.group().decode()
        if s not in seen2:
            seen2.add(s)
            rva = off2rva(m.start())
            if rva:
                print(f"  @0x{rva:X}: {s}")
