# INSIGHT: The kic\switch\user values have CHANGED since we checked the boxes!
# The values are different from the earlier dump. This means:
# 1. The values ARE the switch states (they encode on/off)
# 2. We CAN write them by copying known-good encrypted blobs
#
# The approach: "known-good blob transplant"
# - We already have the WORKING state (all checkboxes checked) in the registry
# - These encrypted values encode "true" for each switch
# - For a FRESH install (no kic entries), we can inject these same blobs
#
# BUT WAIT - there's an even simpler path!
# compatible_type=1 is a PLAIN DWORD that works perfectly.
# The question is: are there PLAIN registry equivalents for the other settings?
#
# Let me check: what does krt.dll's getFuncSwitchState actually read?
# The internal function 0x67230 it calls - let me trace what registry path it queries.

import pefile, struct, re
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

KRT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\krt.dll"
data = open(KRT, 'rb').read()
pe = pefile.PE(KRT, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def rva2off(rva):
    for va, vs, raw, name in secs:
        if va <= rva < va + vs: return rva - va + raw
md = Cs(CS_ARCH_X86, CS_MODE_64)

# The getFuncSwitchState calls internal 0x67230.
# That function likely reads from the kccsdk database (mdbx.dat).
# Let me find all registry path strings in krt.dll
print("=== Registry paths in krt.dll ===")
seen = set()
for m in re.finditer(rb'(?:SOFTWARE|Software)\\Kingsoft\\[\x20-\x7e]{5,80}|kic[/\\]switch[\x20-\x7e]{0,30}', data):
    b = m.start()
    while b > 0 and 32 <= data[b-1] < 127: b -= 1
    e = m.end()
    while e < len(data) and 32 <= data[e] < 127: e += 1
    s = data[b:e].decode('ascii','replace')
    if s not in seen:
        seen.add(s)
        rva = None
        for va, vs, raw, name in secs:
            if raw <= b < raw + vs:
                rva = va + (b - raw)
                break
        print(f"  @0x{rva:X}: {s[:80]}" if rva else f"  @file: {s[:80]}")

# Check for 'kic' strings
print("\n=== kic-related strings in krt.dll ===")
seen2 = set()
for m in re.finditer(rb'[\x20-\x7e]{0,20}kic[\x20-\x7e]{0,30}', data):
    s = m.group().decode('ascii','replace').strip()
    if len(s) > 3 and s not in seen2 and s.lower() != 'kic':
        seen2.add(s)
        print(f"  {s[:70]}")
