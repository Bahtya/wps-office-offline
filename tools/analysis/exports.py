"""Parse PE export table of kshell.dll; find login-related exported functions."""
import struct

path = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll"
data = open(path, 'rb').read()

pe = struct.unpack_from('<I', data, 0x3c)[0]
machine, nsec = struct.unpack_from('<HH', data, pe + 4)[:2]
opt = pe + 24
magic = struct.unpack_from('<H', data, opt)[0]
ddir = opt + (0x60 if magic == 0x10b else 0x70)
exp_rva, exp_sz = struct.unpack_from('<II', data, ddir)

secs = []
so = opt + struct.unpack_from('<H', data, pe + 20)[0]
for i in range(nsec):
    off = so + i * 40
    vs, va, rs, ra = struct.unpack_from('<IIII', data, off + 8)
    secs.append((va, vs, ra, rs))

def r2o(rva):
    for va, vs, ra, rs in secs:
        if va <= rva < va + max(vs, rs):
            return ra + (rva - va)
    return None

print('export dir rva 0x%x size %d' % (exp_rva, exp_sz))
if not exp_rva:
    print('NO EXPORTS'); raise SystemExit

eo = r2o(exp_rva)
ord_base, nfuncs, nnames = struct.unpack_from('<III', data, eo + 16)
funcs_rva, names_rva, ords_rva = struct.unpack_from('<III', data, eo + 28)
names_o, funcs_o, ords_o = r2o(names_rva), r2o(funcs_rva), r2o(ords_rva)

total = 0
hits = []
for i in range(nnames):
    nrva = struct.unpack_from('<I', data, names_o + 4 * i)[0]
    no = r2o(nrva)
    end = data.find(b'\x00', no)
    name = data[no:end].decode(errors='ignore')
    total += 1
    low = name.lower()
    if any(k in low for k in ('loginbar', 'needshow', 'login', 'nologin')):
        ordinal = struct.unpack_from('<H', data, ords_o + 2 * i)[0]
        frva = struct.unpack_from('<I', data, funcs_o + 4 * ordinal)[0]
        hits.append((name, hex(frva)))
print('named exports:', total)
for n, r in hits[:40]:
    print(' ', r, n)
