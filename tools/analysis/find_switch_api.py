# Found the goldmine: type.* identifiers + KIC::SettingsImpl::setSwitch
# Now: find the code that writes these switches and understand the write mechanism.
# The type.* identifiers map to checkboxes:
#   type.scene_recommend = 关闭场景化功能推荐
#   type.template = 关闭模板推荐
#   type.online_template = 关闭在线素材资源推荐
#   type.vas_shellext = 隐藏WPS扩展功能菜单项
#   type.cloud_shellext = 隐藏WPS云文档功能菜单项
#   type.compress_shellext = 隐藏WPS解压拓展菜单项
#   type.desktop_shellext = 隐藏WPS桌面拓展菜单项
#   type.recyclerecovery_shellext = 隐藏WPS回收站拓展菜单项
#   type.freediskspace_shellext = 隐藏WPS释放C盘空间功能菜单项
#   type.wpsai_shellext = 隐藏WPS AI拓展菜单项
#   type.edit_shellext = 隐藏编辑拓展菜单项
#   type.vas_shellnewext = 隐藏WPS新建拓展菜单项
#
# Also found: getFuncSwitchState@product@krt - this is the reader!
# Now find: how to WRITE these without ksomisc.
# The KIC switch data lives in kic\switch\user (encrypted).
# BUT: maybe there's a plain registry path too.

# Check: does ksomisc write to any OTHER location when toggling?
# Look for the code around getFuncSwitchState to find the setFuncSwitch equivalent
import re, pefile, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksomisc.exe"
data = open(DLL, 'rb').read()
pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def off2rva(off):
    for va, vs, raw, name in secs:
        if raw <= off < raw + vs: return off - raw + va
def rva2off(rva):
    for va, vs, raw, name in secs:
        if va <= rva < va + vs: return rva - va + raw

# 1. Check ksomisc.exe EXPORTS for getFuncSwitchState/setFuncSwitchState
pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
exp = getattr(pe, 'DIRECTORY_ENTRY_EXPORT', None)
if exp:
    print(f"=== ksomisc exports: {len(exp.symbols)} ===")
    for s in exp.symbols:
        if s.name and b'Switch' in s.name:
            print(f"  RVA 0x{s.address:X}: {s.name.decode()[:70]}")

# 2. Find krt.dll (the runtime that has getFuncSwitchState)
import os
krt = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\krt.dll"
if os.path.exists(krt):
    krt_data = open(krt, 'rb').read()
    kpe = pefile.PE(krt, fast_load=True)
    kpe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
    kexp = getattr(kpe, 'DIRECTORY_ENTRY_EXPORT', None)
    if kexp:
        print(f"\n=== krt.dll exports: {len(kexp.symbols)} ===")
        for s in kexp.symbols:
            if s.name and (b'Switch' in s.name or b'switch' in s.name):
                print(f"  RVA 0x{s.address:X}: {s.name.decode()[:80]}")

# 3. Check kbase.dll too
kbase = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kbase.dll"
if os.path.exists(kbase):
    kb_data = open(kbase, 'rb').read()
    kbpe = pefile.PE(kbase, fast_load=True)
    kbpe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
    kbexp = getattr(kbpe, 'DIRECTORY_ENTRY_EXPORT', None)
    if kbexp:
        print(f"\n=== kbase.dll exports with switch: ===")
        for s in kbexp.symbols:
            if s.name and b'witch' in s.name:
                print(f"  RVA 0x{s.address:X}: {s.name.decode()[:80]}")

# 4. Search kso.dll for the same
kso = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kso.dll"
if os.path.exists(kso):
    kso_data = open(kso, 'rb').read()
    ksope = pefile.PE(kso, fast_load=True)
    ksope.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
    ksoexp = getattr(ksope, 'DIRECTORY_ENTRY_EXPORT', None)
    if ksoexp:
        print(f"\n=== kso.dll exports with switch: ===")
        for s in ksoexp.symbols:
            if s.name and b'witch' in s.name:
                print(f"  RVA 0x{s.address:X}: {s.name.decode()[:80]}")
