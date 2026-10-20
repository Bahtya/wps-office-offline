"""Search export tables of kshell/kprometheus for AI/VIP/docer button visibility functions."""
import struct

def parse_exports(path):
    data = open(path, 'rb').read()
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    nsec = struct.unpack_from('<H', data, pe + 6)[0]
    opt = pe + 24
    magic = struct.unpack_from('<H', data, opt)[0]
    ddir = opt + (0x60 if magic == 0x10b else 0x70)
    exp_rva = struct.unpack_from('<I', data, ddir)[0]
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
    if not exp_rva:
        return []
    eo = r2o(exp_rva)
    nfuncs, nnames = struct.unpack_from('<II', data, eo + 20)
    funcs_rva, names_rva, ords_rva = struct.unpack_from('<III', data, eo + 28)
    funcs_o, names_o, ords_o = r2o(funcs_rva), r2o(names_rva), r2o(ords_rva)
    out = []
    for i in range(nnames):
        nrva = struct.unpack_from('<I', data, names_o + 4 * i)[0]
        no = r2o(nrva)
        end = data.find(b'\x00', no)
        name = data[no:end].decode(errors='ignore')
        ordinal = struct.unpack_from('<H', data, ords_o + 2 * i)[0]
        frva = struct.unpack_from('<I', data, funcs_o + 4 * ordinal)[0]
        out.append((name, frva))
    return out

import re
pats = re.compile(r'(WpsAi|WPSAI|AiButton|AIBtn|VipBtn|VipButton|needVip|needAI|ShowAI|ShowVip|showAi|DocerBtn|docerEntry|AiEntry|isShow.*Ai|isShow.*Vip|AiVisible|VipVisible)', re.I)
for dll in [r'C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll',
            r'C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kprometheus.dll']:
    try:
        exps = parse_exports(dll)
    except Exception as e:
        print(dll, 'ERR', e); continue
    hits = [(n, hex(r)) for n, r in exps if pats.search(n)]
    print('==', dll.split(chr(92))[-1], f'({len(exps)} exports, {len(hits)} hits) ==')
    for n, r in hits[:30]:
        print(' ', r, n[:110])
