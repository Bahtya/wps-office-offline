# Stub out: CrossTerminal(WPS随行) + AppMarket(应用市场) buttons in kprometheus.dll
# Method: for each function-name string, find lea xref -> walk back to prologue -> stub 31 C0 C3
import re, struct, shutil, os, pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kprometheus.dll"
data = open(DLL, 'rb').read()
pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData) for s in pe.sections]

def off2rva(off):
    for va, vs, raw in secs:
        if raw <= off < raw + vs: return off - raw + va
def rva2off(rva):
    for va, vs, raw in secs:
        if va <= rva < va + vs: return rva - va + raw

TARGETS = [
    b'KPromeTabBarImpl::initCrossTerminalBtn',
    b'KPromeTabBar2024Private::ensureCrossTerminalButton::<lambda_b24ea2e189743f74ada1e16af',
    b'KPromeTabBar2024Private::ensureCrossTerminalButton::<lambda_340fb68bfad80ece834276a07',
    b'KPromeTabBar2024Private::ensureCrossTerminalButton',
    b'KPromeTabBarImpl::initAppMarketBtn',
    b'KPromeTabBarImpl::checkInitAppMarketBtn',
    b'KPromeTabBar2024Private::ensureAppMarketButton',
    b'KPromeTabBar2024Private::ensureMobileButton',
    b'KPromeTabBarImpl::initUpgradeBtn',
    b'KPromeTabBar2024Private::ensureUpgradeButton',
    b'KPromeTabBar2024Private::ensureDownloadGuideWidget',
    b'KPromeTabBar2024Private::ensureWhatsNewButton',
    b'KPromeTabBar2024Private::ensureStandardWhatsNewButton',
    b'KPromeTabBar2024Private::ensureTemplateMarketButton',
]

str_rva = {}
for t in TARGETS:
    i = data.find(t)
    # only first occurrence
    if i >= 0:
        r = off2rva(i)
        if r: str_rva[r] = t.decode()

tva, tvs, traw = secs[0]
code = data[traw:traw + tvs]
hits = []
for i in range(len(code) - 7):
    if code[i] == 0x48 and code[i+1] == 0x8D and (code[i+2] & 0xC7) == 0x05:
        disp = struct.unpack('<i', code[i+3:i+7])[0]
        t = tva + i + 7 + disp
        if t in str_rva:
            hits.append((tva + i, str_rva[t]))
print(f"xref hits: {len(hits)}")

def find_prologue(hit_off):
    back = hit_off
    limit = max(hit_off - 0x1000, traw)
    while back > limit:
        back -= 1
        prev = data[back - 1] if back > 0 else 0
        if prev in (0xC3, 0xCC, 0x90):
            b0 = data[back]
            if b0 in (0x55, 0x53, 0x56, 0x57, 0x41, 0x40) or \
               (b0 == 0x48 and data[back+1] in (0x89, 0x83, 0x81, 0x8B)) or \
               (b0 == 0x40 and data[back+1] in (0x53, 0x55, 0x56, 0x57)):
                return back
    return None

md = Cs(CS_ARCH_X86, CS_MODE_64)
patched = []
for rva, name in hits:
    off = rva2off(rva)
    start = find_prologue(off)
    if start is None:
        print(f"  [noprologue] {name}")
        continue
    srva = off2rva(start)
    head = data[start:start+6].hex()
    # sanity: not already stubbed, looks like code
    if data[start] == 0x31:
        print(f"  [already] {name} @0x{srva:X}")
        continue
    patched.append((start, srva, name, head))

print(f"\ncandidates to patch: {len(patched)}")
for start, srva, name, head in patched:
    print(f"  0x{srva:X} head={head} <- {name[:60]}")

# APPLY
bak = DLL + '.korig2'
if not os.path.exists(bak):
    shutil.copyfile(DLL, bak)
    print("\nbackup ->", os.path.basename(bak))
with open(DLL, 'r+b') as f:
    for start, srva, name, head in patched:
        f.seek(start)
        f.write(b'\x31\xc0\xc3')
        print(f"  PATCHED 0x{srva:X} {name[:55]}")
