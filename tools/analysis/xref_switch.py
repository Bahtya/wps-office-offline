# Find code references to switch strings in kstartpage.dll
# Method: scan .text for `lea r64, [rip+disp32]` resolving to the string RVA
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\addons\kstartpage\kstartpage.dll"
TARGETS = [b'StartPageNavigationHideNewFromTemplate', b'DisableOfficeNavHomeDocer', b'newfromtemplate']

pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
data = open(DLL, 'rb').read()

def off2rva(off):
    for va, vs, raw, name in secs:
        if raw <= off < raw + vs:
            return off - raw + va
    return None
def rva2off(rva):
    for va, vs, raw, name in secs:
        if va <= rva < va + vs:
            return rva - va + raw
    return None

# locate target string RVAs
str_rvas = {}
for t in TARGETS:
    i = data.find(t)
    while i >= 0:
        r = off2rva(i)
        if r:
            str_rvas[r] = t.decode()
        i = data.find(t, i + 1)
print("string RVAs:", {hex(k): v for k, v in str_rvas.items()})

# find .text extent
text = secs[0]
tva, tvs, traw, _ = text
md = Cs(CS_ARCH_X86, CS_MODE_64)
md.detail = False

hits = []
code = data[traw:traw + tvs]
# brute: find all '48 8D' (lea r64) and check disp
import struct
for i in range(len(code) - 7):
    if code[i] == 0x48 and code[i+1] == 0x8D:
        modrm = code[i+2]
        if (modrm & 0xC7) == 0x05:  # mod=00, rm=101 => [rip+disp32]
            disp = struct.unpack('<i', code[i+3:i+7])[0]
            instr_rva = tva + i
            target = instr_rva + 7 + disp
            if target in str_rvas:
                hits.append((instr_rva, target, str_rvas[target]))
print(f"xref hits: {len(hits)}")
for rva, tgt, name in hits:
    print(f"  lea @RVA 0x{rva:X} -> 0x{tgt:X} ({name})")

# disassemble around each hit
for rva, tgt, name in hits:
    off = rva2off(rva)
    print(f"\n=== context of hit 0x{rva:X} ({name}) ===")
    start = max(0, off - 120)
    chunk = data[start:off + 200]
    base_rva = off2rva(start)
    cnt = 0
    for ins in md.disasm(chunk, base_rva):
        mark = " <<<" if ins.address == rva else ""
        print(f"  0x{ins.address:08X}: {ins.mnemonic:<8} {ins.op_str}{mark}")
        cnt += 1
        if cnt > 45: break
