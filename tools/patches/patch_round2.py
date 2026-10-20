# Surgical patch round 2:
# 1. ksolite!KCopilotEntryManager::checkGlobalEntryVisible -> return false  (kills WPS AI tab)
# 2. officenav.kui: remove newfromtemplate entry + AI entries (kills 稻壳AI模板 button)
import os, re, shutil, pefile

BASE = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6"

# ---- 1. ksolite patch ----
dll = os.path.join(BASE, "ksolite.dll")
pe = pefile.PE(dll, fast_load=True)
rva = 0x00017500
off = None
for s in pe.sections:
    if s.VirtualAddress <= rva < s.VirtualAddress + s.Misc_VirtualSize:
        off = rva - s.VirtualAddress + s.PointerToRawData
        break
data = bytearray(open(dll, 'rb').read())
head = bytes(data[off:off+8])
print(f"ksolite RVA 0x{rva:X} fileoff 0x{off:X} head={head.hex()}")
if bytes(data[off:off+3]) != b'\x31\xc0\xc3':
    bak = dll + '.korig'
    if not os.path.exists(bak):
        shutil.copyfile(dll, bak)
    data[off:off+3] = b'\x31\xc0\xc3'
    open(dll, 'wb').write(data)
    print("ksolite patched: checkGlobalEntryVisible -> false")
else:
    print("ksolite already patched")

# ---- 2. officenav.kui ----
kui = os.path.join(BASE, r"addons\kstartpage\res\kuip\officenav.kui")
src = open(kui, encoding='utf-8', errors='replace').read()
orig = src
# remove the docer template entry (the 稻壳AI模板 button)
src = re.sub(r'<KTemplatePageEntry[^>]*id="newfromtemplate"[^>]*/>\s*', '', src)
# remove AI entries on start page
src = re.sub(r'<KAIAssistantEntry[^>]*/>\s*', '', src)
src = re.sub(r'<KAIPPTEntry[^>]*/>\s*', '', src)
src = re.sub(r'<KAINoteEntry[^>]*/>\s*', '', src)
src = re.sub(r'<KAcademicAIEntry[^>]*/>\s*', '', src)
src = re.sub(r'<KCmdPolicyUrlEntry[^>]*id="digitalemployee"[^>]*/>\s*', '', src)
if src != orig:
    bak = kui + '.korig'
    if not os.path.exists(bak):
        shutil.copyfile(kui, bak)
    open(kui, 'w', encoding='utf-8').write(src)
    print(f"officenav.kui patched ({len(orig)} -> {len(src)})")
else:
    print("officenav.kui no change")
