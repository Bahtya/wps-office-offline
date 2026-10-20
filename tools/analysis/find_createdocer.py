# Locate createDocerTabButton via log-string xref, stub it to xor eax,eax;ret
import pefile, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kprometheus.dll"
pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData) for s in pe.sections]
data = open(DLL, 'rb').read()

def off2rva(off):
    for va, vs, raw in secs:
        if raw <= off < raw + vs: return off - raw + va
def rva2off(rva):
    for va, vs, raw in secs:
        if va <= rva < va + vs: return rva - va + raw

# string RVAs
targets = {}
for s in [b'createDocerTabButton: personal button created, source: %1',
          b'KPromeTabBar2024Private::ensurePromotionButton',
          b'removeDocerTabButton by: %1']:
    i = data.find(s)
    while i >= 0:
        r = off2rva(i)
        if r: targets[r] = s.decode()[:50]
        i = data.find(s, i+1)

# .text = first section
tva, tvs, traw = secs[0]
code = data[traw:traw+tvs]
hits = []
for i in range(len(code)-7):
    if code[i] == 0x48 and code[i+1] == 0x8D:
        modrm = code[i+2]
        if (modrm & 0xC7) == 0x05:
            disp = struct.unpack('<i', code[i+3:i+7])[0]
            t = tva + i + 7 + disp
            if t in targets:
                hits.append((tva+i, t, targets[t]))
print("xrefs:")
for rva, t, name in hits:
    print(f"  lea @0x{rva:X} -> {name}")

md = Cs(CS_ARCH_X86, CS_MODE_64)
# For the createDocerTabButton log xref, walk back to function start
for rva, t, name in hits:
    if 'personal button created' not in name:
        continue
    off = rva2off(rva)
    # scan back up to 0x800 bytes for prologue candidates preceded by CC/alignment
    start = None
    back = off
    limit = max(off - 0x900, traw)
    while back > limit:
        back -= 1
        # common prologues: 48 89 5C 24 (mov [rsp+..],rbx) / 55 (push rbp) / 41 57 / 48 83 EC / 40 53
        b = data[back]
        prev = data[back-1]
        isret = prev in (0xC3, 0xCC)
        if isret:
            nxt = data[back]
            if (b in (0x55,) or (b == 0x48 and data[back+1] in (0x89, 0x83)) or b == 0x41 or (b == 0x40) or b == 0x53 or b == 0x56 or b == 0x57):
                start = back
                break
    print(f"\nfunction start guess for {name[:40]}: 0x{off2rva(start):X}" if start else "no start found")
    if start:
        cnt = 0
        for ins in md.disasm(data[start:start+220], off2rva(start)):
            print(f"  0x{ins.address:08X}: {ins.mnemonic:<8} {ins.op_str}")
            cnt += 1
            if cnt > 40: break
