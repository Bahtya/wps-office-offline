# Deep dive: find the exact config write for each checkbox.
# ksomisc uses Qt settings or direct registry. Search for:
# 1. All strings in .rdata around 0x268-0x26A (the settings cluster)
# 2. QSettings/writeConfig patterns
# 3. The actual registry write function calls
import re, struct, pefile

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksomisc.exe"
data = open(DLL, 'rb').read()
pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def off2rva(off):
    for va, vs, raw, name in secs:
        if raw <= off < raw + vs: return off - raw + va
def rva2off(rva):
    for va, vs, raw, name in secs:
        if va <= rva < va + vs: return rva - va + raw

# Dump the settings cluster region: RVA 0x267000-0x270000 (.rdata raw starts at 0x24D000, VA 0x24E000)
# So file offset for RVA 0x268000 = 0x268000 - 0x24E000 + 0x24D000 = 0x267000
rdata_va, rdata_vs, rdata_raw, _ = next(s for s in secs if 'rdata' in s[3])

def dump_region(rva_lo, rva_hi, label):
    print(f"\n=== {label} (RVA 0x{rva_lo:X}-0x{rva_hi:X}) ===")
    off_lo = rva2off(rva_lo)
    off_hi = rva2off(rva_hi)
    for m in re.finditer(rb'[\x20-\x7e]{6,}', data[off_lo:off_hi]):
        rva = off2rva(off_lo + m.start())
        print(f"  @0x{rva:X}: {m.group().decode()[:90]}")

# The settings identifiers cluster
dump_region(0x267C00, 0x268E00, "settings cluster 1")
dump_region(0x29C800, 0x29CA00, "closeButton area")
