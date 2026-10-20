# Key finding: getFuncSwitchState has NO setFuncSwitchState counterpart exported!
# That means ksomisc must write through a different path.
#
# Let me trace what ksomisc actually does when you check a box:
# 1. It calls getFuncSwitchState to read current state
# 2. For writing - it must use KIC::SettingsImpl::setSwitch (found in string table)
#    or write to some file/registry directly.
#
# Check: krt.dll getFuncSwitchState - what does it read?
# Disassemble it to find the data source.
import pefile, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

KRT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\krt.dll"
data = open(KRT, 'rb').read()
pe = pefile.PE(KRT, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def rva2off(rva):
    for va, vs, raw, name in secs:
        if va <= rva < va + vs: return rva - va + raw
md = Cs(CS_ARCH_X86, CS_MODE_64)

# Disassemble getFuncSwitchState @ RVA 0x3AFD0
rva = 0x3AFD0
off = rva2off(rva)
print(f"getFuncSwitchState @RVA 0x{rva:X} fileoff 0x{off:X}")
print(f"head: {data[off:off+8].hex()}")
for i, ins in enumerate(md.disasm(data[off:off+200], rva)):
    print(f"  0x{ins.address:08X}: {ins.mnemonic:<9} {ins.op_str}")
    if i > 30: break

# Also check getFuncRegSwitchState @ 0x3AA80
print(f"\ngetFuncRegSwitchState @RVA 0x3AA80:")
off2 = rva2off(0x3AA80)
for i, ins in enumerate(md.disasm(data[off2:off2+200], 0x3AA80)):
    print(f"  0x{ins.address:08X}: {ins.mnemonic:<9} {ins.op_str}")
    if i > 30: break
