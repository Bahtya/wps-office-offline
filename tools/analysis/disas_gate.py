# Disassemble KCloudSvrProxy::isEnableForceLogin and isLogined in ksolite.dll
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksolite.dll"
TARGETS = {
    0x002256F0: "isEnableForceLogin",
    0x002257D0: "isLogined",
    0x002257A0: "isLoginWinVisible",
    0x002223A0: "getLoginInfoMap",
}

pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
data = open(DLL, 'rb').read()
md = Cs(CS_ARCH_X86, CS_MODE_64)

def rva2off(rva):
    for va, vs, raw, name in secs:
        if va <= rva < va + vs:
            return rva - va + raw, name
    return None, None

for rva, name in TARGETS.items():
    off, sec = rva2off(rva)
    print(f"\n=== {name} RVA 0x{rva:08X} fileoff 0x{off:X} ({sec}) ===")
    print("bytes:", data[off:off+12].hex())
    cnt = 0
    for ins in md.disasm(data[off:off+160], rva):
        print(f"  0x{ins.address:08X}: {ins.mnemonic:<8} {ins.op_str}")
        cnt += 1
        if ins.mnemonic == 'ret' or cnt > 25:
            break
