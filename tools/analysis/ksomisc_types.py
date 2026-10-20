# Found: "type.scene_recommend" "type.template" "type.online_template"
# These look like KIC switch type identifiers! Now find:
# 1. How ksomisc reads/writes these (the kic API)
# 2. What other "type.*" identifiers exist for all checkboxes
import re, pefile

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksomisc.exe"
data = open(DLL, 'rb').read()
pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def off2rva(off):
    for va, vs, raw, name in secs:
        if raw <= off < raw + vs: return off - raw + va

print("=== All type.* identifiers ===")
seen = set()
for m in re.finditer(rb'type\.[a-z_]{3,40}', data):
    s = m.group().decode()
    if s not in seen:
        seen.add(s)
        rva = off2rva(m.start())
        print(f"  @0x{rva:X}: {s}")

print("\n=== All kic/switch API references ===")
for m in re.finditer(rb'(?:getKicValue|setKicValue|getSwitch|setSwitch|KicSettings|writeSwitch|readSwitch|getFuncSwitch|setFuncSwitch)', data):
    b = m.start()
    while b > 0 and 32 <= data[b-1] < 127: b -= 1
    e = m.end()
    while e < len(data) and 32 <= data[e] < 127: e += 1
    s = data[b:e].decode('ascii','replace')
    rva = off2rva(b)
    print(f"  @0x{rva:X}: {s[:80]}")

print("\n=== compatible_type context ===")
i = data.find(b'compatible_type')
if i >= 0:
    rva = off2rva(i)
    print(f"  @0x{rva:X}: compatible_type")
    # dump around
    lo = max(0, i-200); hi = i+200
    for m in re.finditer(rb'[\x20-\x7e]{5,}', data[lo:hi]):
        print(f"    {m.group().decode()[:80]}")
