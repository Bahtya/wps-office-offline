# Disassemble IsStartUpInForceLoginMode at RVA 0x55B400 in kshell.dll
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll"
RVA = 0x55B400

pe = pefile.PE(DLL, fast_load=True)
for s in pe.sections:
    if s.VirtualAddress <= RVA < s.VirtualAddress + s.Misc_VirtualSize:
        off = RVA - s.VirtualAddress + s.PointerToRawData
        print(f"section {s.Name.decode().strip()} fileoff 0x{off:X}")
        break

data = open(DLL, 'rb').read()
code = data[off:off+96]
md = Cs(CS_ARCH_X86, CS_MODE_64)
for ins in md.disasm(code, RVA):
    print(f"0x{ins.address:08X}: {ins.mnemonic:<10} {ins.op_str}")
    if ins.mnemonic == 'ret':
        break
