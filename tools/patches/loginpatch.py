"""kshell.dll 登录提示补丁工具
patch   -> 对 4 个函数写入 xor eax,eax; ret (恒返回 false)
restore -> 用 .korig 备份还原
"""
import struct, sys, os

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll"
ORIG = DLL + '.korig'
STUB = bytes([0x31, 0xC0, 0xC3])  # xor eax,eax ; ret

# RVA 与文件偏移的映射需按节表计算
data = open(DLL, 'rb').read()
pe = struct.unpack_from('<I', data, 0x3c)[0]
nsec = struct.unpack_from('<H', data, pe + 6)[0]
opt = pe + 24
so = opt + struct.unpack_from('<H', data, pe + 20)[0]
secs = []
for i in range(nsec):
    off = so + i * 40
    vs, va, rs, ra = struct.unpack_from('<IIII', data, off + 8)
    secs.append((va, vs, ra, rs))

def r2o(rva):
    for va, vs, ra, rs in secs:
        if va <= rva < va + max(vs, rs):
            return ra + (rva - va)
    return None

TARGETS = {
    0x77fcf0: 'isNeedShowLoginBar',
    0x77fb70: 'isNeedShowGuidedLoginTip',
    0x77f4b0: 'isNeedShowForceLoginTip',
    0x55b400: 'IsStartUpInForceLoginMode',
}

cmd = sys.argv[1] if len(sys.argv) > 1 else 'patch'

if cmd == 'patch':
    if os.path.exists(ORIG):
        print('backup already exists, skip backup')
    else:
        open(ORIG, 'wb').write(data)
        print('backup ->', ORIG)
    buf = bytearray(data)
    for rva, name in TARGETS.items():
        fo = r2o(rva)
        cur = bytes(buf[fo:fo+3])
        if cur == STUB:
            print(f'[already] {name} @0x{rva:x}')
            continue
        buf[fo:fo+3] = STUB
        print(f'[patched] {name} RVA=0x{rva:x} fileoff=0x{fo:x} (was {cur.hex()})')
    open(DLL, 'wb').write(buf)
    print('written:', DLL)
elif cmd == 'restore':
    if not os.path.exists(ORIG):
        print('no backup'); sys.exit(1)
    open(DLL, 'wb').write(open(ORIG, 'rb').read())
    os.remove(ORIG)
    print('restored from backup')
elif cmd == 'status':
    for rva, name in TARGETS.items():
        fo = r2o(rva)
        cur = data[fo:fo+3]
        print(f'{name}: {"PATCHED" if cur==STUB else "original"} ({cur.hex()})')
