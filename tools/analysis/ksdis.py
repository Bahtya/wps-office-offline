"""Disassemble any RVA in a DLL by export-name regex (ksolite)."""
import struct, re, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

dll = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksolite.dll"
data = open(dll, 'rb').read()
pe = struct.unpack_from('<I', data, 0x3c)[0]
nsec = struct.unpack_from('<H', data, pe + 6)[0]
opt = pe + 24
magic = struct.unpack_from('<H', data, opt)[0]
ddir = opt + (0x60 if magic == 0x10b else 0x70)
exp_rva = struct.unpack_from('<I', data, ddir)[0]
so = opt + struct.unpack_from('<H', data, pe + 20)[0]
secs = []
for i in range(nsec):
    off = so + i * 40
    vs, va, rs, ra = struct.unpack_from('<IIII', data, off + 8)
    nm = data[off:off+8].rstrip(b'\x00').decode()
    secs.append((va, vs, ra, rs, nm))
def r2o(rva):
    for va, vs, ra, rs, nm in secs:
        if va <= rva < va + max(vs, rs):
            return ra + (rva - va)
    return None
eo = r2o(exp_rva)
nfuncs, nnames = struct.unpack_from('<II', data, eo + 20)
funcs_rva, names_rva, ords_rva = struct.unpack_from('<III', data, eo + 28)
funcs_o, names_o, ords_o = r2o(funcs_rva), r2o(names_rva), r2o(ords_rva)

pat = re.compile(sys.argv[1])
size = int(sys.argv[2], 0) if len(sys.argv) > 2 else 0x120
for i in range(nnames):
    nrva = struct.unpack_from('<I', data, names_o + 4 * i)[0]
    no = r2o(nrva)
    end = data.find(b'\x00', no)
    name = data[no:end].decode(errors='ignore')
    if pat.search(name):
        ordinal = struct.unpack_from('<H', data, ords_o + 2 * i)[0]
        frva = struct.unpack_from('<I', data, funcs_o + 4 * ordinal)[0]
        fo = r2o(frva)
        print(f'== {name[:110]}')
        print(f'   RVA=0x{frva:x} fileoff=0x{fo:x}')
        md = Cs(CS_ARCH_X86, CS_MODE_64)
        n = 0
        for ins in md.disasm(data[fo:fo+size], frva):
            print(f'   0x{ins.address:x}: {ins.mnemonic:8s} {ins.op_str}')
            n += 1
            if n > int(sys.argv[3] if len(sys.argv) > 3 else 45): break
        print()
