# SHA256 doesn't match the existing keys. The key isn't a simple SHA256 of the name.
# Let me try other hashes and also check if the KRT module reveals the algorithm.
#
# But WAIT - there's a much more practical approach I've been missing:
# ksomisc.exe uses `getFuncSwitchState@product@krt` which reads from a source.
# The KRT (Kingsoft Runtime) module is a shared library that WPS also loads.
#
# The REAL practical approach: find the WRITER by looking at what ksomisc does
# when the OK button is clicked. Since there's no exported setFuncSwitchState,
# the write must go through a different mechanism.
#
# KEY INSIGHT: The kccsdkpriortydb (mdbx.dat) IS the config store!
# krt.dll reads from it. ksomisc probably writes to it through the kccsdk API.
# The kccsdk.dll is loaded in the WPS process.
#
# Let me check: does kccsdk have a setConfig/write API?

import os, pefile

for mod in ["kccsdk.dll", "kconfigcentersdk.dll", "kbaseconfigcenter.dll", "kbaseconfigcenter64.dll"]:
    p = rf"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\{mod}"
    if not os.path.exists(p):
        p2 = rf"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\addons\kconfigcentersdk\{mod}"
        if os.path.exists(p):
            p = p2
        else:
            continue
    pe = pefile.PE(p, fast_load=True)
    pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
    exp = getattr(pe, 'DIRECTORY_ENTRY_EXPORT', None)
    if not exp: continue
    hits = [(s.address, s.name.decode()) for s in exp.symbols if s.name and any(k in s.name.decode().lower() for k in ['setconfig', 'writeconfig', 'setvalue', 'setswitch', 'putvalue', 'saveconfig', 'updateconfig', 'setitem'])]
    if hits:
        print(f"=== {mod}: {len(hits)} write APIs ===")
        for rva, n in sorted(hits)[:15]:
            print(f"  RVA 0x{rva:X}: {n[:75]}")

# Also: check if there's a kccsdk in the addon
addon = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\addons\kconfigcentersdk"
if os.path.exists(addon):
    print(f"\n=== kconfigcentersdk addon dir ===")
    for root, dirs, files in os.walk(addon):
        for f in files:
            if f.endswith('.dll'):
                print(f"  {os.path.join(root, f)}")

# Check what kccsdk.dll actually is
for candidate in [
    r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kccsdk.dll",
]:
    if os.path.exists(candidate):
        print(f"\n=== {os.path.basename(candidate)} exists, size={os.path.getsize(candidate)} ===")
        pe = pefile.PE(candidate, fast_load=True)
        pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
        exp = getattr(pe, 'DIRECTORY_ENTRY_EXPORT', None)
        if exp:
            print(f"exports: {len(exp.symbols)}")
            for s in exp.symbols[:20]:
                if s.name:
                    print(f"  {s.name.decode()[:70]}")
