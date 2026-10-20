"""在 DLL 中查找引用指定文件偏移处字符串的代码点, 并定位所属导出函数."""
import struct, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

dll = sys.argv[1]
str_off = int(sys.argv[2], 16)          # 字符串的文件偏移
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

def o2r(fo):
    for va, vs, ra, rs, nm in secs:
        if ra <= fo < ra + rs:
            return va + (fo - ra)
    return None
def r2o(rva):
    for va, vs, ra, rs, nm in secs:
        if va <= rva < va + max(vs, rs):
            return ra + (rva - va)
    return None

str_rva = o2r(str_off)
print('string fileoff 0x%x -> RVA 0x%x' % (str_off, str_rva))

# 解析导出函数表, 建立 (rva, name) 列表
eo = r2o(exp_rva)
nfuncs, nnames = struct.unpack_from('<II', data, eo + 20)
funcs_rva, names_rva, ords_rva = struct.unpack_from('<III', data, eo + 28)
funcs_o, names_o, ords_o = r2o(funcs_rva), r2o(names_rva), r2o(ords_rva)
funcs = []
for i in range(nnames):
    nrva = struct.unpack_from('<I', data, names_o + 4 * i)[0]
    no = r2o(nrva)
    end = data.find(b'\x00', no)
    name = data[no:end].decode(errors='ignore')
    ordinal = struct.unpack_from('<H', data, ords_o + 2 * i)[0]
    frva = struct.unpack_from('<I', data, funcs_o + 4 * ordinal)[0]
    funcs.append((frva, name))
funcs.sort()
print('exports:', len(funcs))

# 在 .text 中扫 lea reg,[rip+disp] 指向 str_rva
md = Cs(CS_ARCH_X86, CS_MODE_64)
text = None
for va, vs, ra, rs, nm in secs:
    if nm == '.text':
        text = (va, ra, rs)
tva, tra, trs = text
hits = 0
code = data[tra:tra+trs]
# 快速法: 直接找 4 字节 disp 使 rip+disp==str_rva 的 lea (48 8d 0d/15/05...)
import re
for m in re.finditer(rb'\x48\x8d[\x05\x0d\x15\x1d\x25\x2d\x35\x3d]', code):
    pos = m.start()
    ins_rva = tva + pos
    disp = struct.unpack_from('<i', code, pos + 3)[0]
    target = ins_rva + 7 + disp
    if target == str_rva:
        # 找所属函数: rva <= ins_rva 的最大导出函数
        lo, hi = 0, len(funcs) - 1
        owner = None
        for i, (frva, name) in enumerate(funcs):
            if frva <= ins_rva:
                owner = (frva, name)
            else:
                break
        print(f'XREF @RVA 0x{ins_rva:x}  owner: 0x{owner[0]:x} {owner[1][:100]}')
        hits += 1
        if hits > 6: break
print('total xrefs:', hits)
