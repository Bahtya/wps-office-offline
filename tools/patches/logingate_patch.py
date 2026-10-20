# Patch ksolite.dll login gates:
#   KCloudSvrProxy::isEnableForceLogin (fileoff 0x224AF0) -> return FALSE  (31 C0 C3)
#   KCloudSvrProxy::isLogined         (fileoff 0x224BD0) -> return TRUE   (B8 01 00 00 00 C3)
import shutil, sys

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksolite.dll"
ORIG = DLL + ".korig"

PATCHES = [
    # (fileoff, expect_first4, stub, name)
    (0x224AF0, bytes([0x40, 0x53, 0x48, 0x83]), bytes([0x31, 0xC0, 0xC3]), "isEnableForceLogin=false"),
    (0x224BD0, bytes([0x40, 0x53, 0x48, 0x83]), bytes([0xB8, 0x01, 0x00, 0x00, 0x00, 0xC3]), "isLogined=true"),
]

mode = sys.argv[1] if len(sys.argv) > 1 else 'patch'

if mode == 'restore':
    shutil.copyfile(ORIG, DLL)
    print("ksolite.dll restored from .korig")
    sys.exit(0)

import os
if not os.path.exists(ORIG):
    shutil.copyfile(DLL, ORIG)
    print("backup created:", ORIG)

with open(DLL, 'rb') as f:
    data = bytearray(f.read())

for off, expect, stub, name in PATCHES:
    cur = bytes(data[off:off+len(expect)])
    already = bytes(data[off:off+len(stub)]) == stub
    print(f"{name} @0x{off:X}: cur={cur.hex()}", end=' ')
    if already:
        print("-> already patched")
        continue
    if cur != expect:
        print("-> UNEXPECTED, abort")
        sys.exit(1)
    data[off:off+len(stub)] = stub
    print("-> patched")

with open(DLL, 'wb') as f:
    f.write(data)
print("ksolite.dll login gates patched")
