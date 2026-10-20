# Patch kshell!KxApplication::IsStartUpInForceLoginMode -> always return false
# RVA 0x55B400 / file offset 0x55A800. stub: 31 C0 C3 (xor eax,eax; ret)
import shutil, sys

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll"
ORIG = DLL + ".korig"
OFF = 0x55A800
EXPECT = bytes([0x40, 0x53, 0x48, 0x83])  # push rbx; sub rsp,0x30
STUB = bytes([0x31, 0xC0, 0xC3])

mode = sys.argv[1] if len(sys.argv) > 1 else 'patch'

with open(DLL, 'rb') as f:
    data = bytearray(f.read())

cur = bytes(data[OFF:OFF+4])
print(f"current bytes @0x{OFF:X}: {cur.hex()}")

if mode == 'status':
    print('patched' if cur == STUB else 'original')
    sys.exit(0)

if mode == 'restore':
    shutil.copyfile(ORIG, DLL)
    print('restored from .korig')
    sys.exit(0)

if cur == STUB:
    print('already patched')
    sys.exit(0)
if cur != EXPECT:
    print('UNEXPECTED header — abort')
    sys.exit(1)

data[OFF:OFF+3] = STUB
with open(DLL, 'wb') as f:
    f.write(data)
print('patched: IsStartUpInForceLoginMode -> false')
