"""ksolite.dll 插件加载器补丁: loadByAcceptFlowControl -> mov eax,3; ret (返回已加载状态)"""
import struct, sys, os

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksolite.dll"
ORIG = DLL + '.korig'
STUB = bytes([0xB8, 0x03, 0x00, 0x00, 0x00, 0xC3])  # mov eax,3 ; ret

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

# KPluginDependLoader::loadByAcceptFlowControl RVA=0x210140 (fileoff 0x20f540)
TARGETS = {
    0x210140: 'KPluginDependLoader::loadByAcceptFlowControl',
}

cmd = sys.argv[1] if len(sys.argv) > 1 else 'patch'
if cmd == 'patch':
    if not os.path.exists(ORIG):
        open(ORIG, 'wb').write(data)
        print('backup ->', ORIG)
    buf = bytearray(data)
    for rva, name in TARGETS.items():
        fo = r2o(rva)
        cur = bytes(buf[fo:fo+6])
        if cur == STUB:
            print(f'[already] {name}')
            continue
        buf[fo:fo+6] = STUB
        print(f'[patched] {name} RVA=0x{rva:x} fileoff=0x{fo:x} (was {cur.hex()})')
    open(DLL, 'wb').write(buf)
elif cmd == 'restore':
    open(DLL, 'wb').write(open(ORIG, 'rb').read())
    os.remove(ORIG)
    print('restored')
elif cmd == 'status':
    for rva, name in TARGETS.items():
        fo = r2o(rva)
        print(name, 'PATCHED' if data[fo:fo+6] == STUB else 'original', data[fo:fo+6].hex())
