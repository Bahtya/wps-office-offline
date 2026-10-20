"""kprometheus.dll 推广按钮补丁: promotionTabClicked / onPromotionTabClicked -> ret"""
import struct, sys, os

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kprometheus.dll"
ORIG = DLL + '.korig'
STUB = bytes([0xC3])  # void 函数直接 ret

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
    0x317f0: 'KPromeTabBar::promotionTabClicked',
    0x550f00: 'KPromeJsApiClient::onPromotionTabClicked',
}

cmd = sys.argv[1] if len(sys.argv) > 1 else 'patch'
if cmd == 'patch':
    if not os.path.exists(ORIG):
        open(ORIG, 'wb').write(data)
        print('backup ->', ORIG)
    else:
        print('backup exists')
    buf = bytearray(data)
    for rva, name in TARGETS.items():
        fo = r2o(rva)
        cur = bytes(buf[fo:fo+1])
        if cur == STUB:
            print(f'[already] {name}')
            continue
        buf[fo] = 0xC3
        print(f'[patched] {name} RVA=0x{rva:x} fileoff=0x{fo:x} (was {cur.hex()})')
    open(DLL, 'wb').write(buf)
elif cmd == 'restore':
    open(DLL, 'wb').write(open(ORIG, 'rb').read())
    os.remove(ORIG)
    print('restored')
elif cmd == 'status':
    for rva, name in TARGETS.items():
        fo = r2o(rva)
        print(name, 'PATCHED' if data[fo] == 0xC3 else 'original')
