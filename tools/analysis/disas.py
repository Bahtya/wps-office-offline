"""Disassemble exported functions of kshell.dll with correct RVA->fileoff mapping."""
import struct, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

path = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll"
data = open(path, 'rb').read()

pe = struct.unpack_from('<I', data, 0x3c)[0]
nsec = struct.unpack_from('<H', data, pe + 6)[0]
opt = pe + 24
so = opt + struct.unpack_from('<H', data, pe + 20)[0]
secs = []
for i in range(nsec):
    off = so + i * 40
    vs, va, rs, ra = struct.unpack_from('<IIII', data, off + 8)
    secs.append((va, vs, ra, rs, data[off:off+8].rstrip(b'\x00').decode()))

def r2o(rva):
    for va, vs, ra, rs, nm in secs:
        if va <= rva < va + max(vs, rs):
            return ra + (rva - va)
    return None

funcs = {
    'isNeedShowLoginBar':       0x77fcf0,
    'isNeedShowGuidedLoginTip': 0x77fb70,
    'isNeedShowForceLoginTip':  0x77f4b0,
}
md = Cs(CS_ARCH_X86, CS_MODE_64)
name = sys.argv[1] if len(sys.argv) > 1 else 'isNeedShowLoginBar'
rva = funcs[name]
fo = r2o(rva)
print(f'== {name} RVA=0x{rva:x} fileoff=0x{fo:x} ==')
for ins in md.disasm(data[fo:fo+0x200], rva):
    print(f'0x{ins.address:x}: {ins.mnemonic:8s} {ins.op_str}')
    if ins.mnemonic == 'ret':
        break
