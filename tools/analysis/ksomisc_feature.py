# Find the 功能定制 (feature customization) checkbox -> config mapping.
# The checkboxes we need:
#   关闭模板推荐 / 关闭在线素材资源推荐 / 关闭场景化功能推荐
#   隐藏WPS AI拓展菜单项 / 隐藏编辑拓展菜单项 / ... all 隐藏WPS*菜单项
#   兼容离线状态下的未登录使用方式 (compatible_type)
# Search for their config identifiers in ksomisc
import re, pefile

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksomisc.exe"
data = open(DLL, 'rb').read()
pe = pefile.PE(DLL, fast_load=True)
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def off2rva(off):
    for va, vs, raw, name in secs:
        if raw <= off < raw + vs: return off - raw + va

# The 功能定制 page strings - search for key patterns
# English sources for the checkboxes:
#   "Close template recommendation" -> CloseTemplateRecommend?
#   "Close online material resource" -> ?
#   "Close scenario feature recommendation" -> ?
#   "Hide WPS AI extend menu item" -> ?
# Search around these English phrases in rdata
print("=== All strings containing Recommend/Template/Material/Scenario/Personal/Menu ===")
seen = set()
for kw in [rb'[A-Za-z]{0,15}[Rr]ecommend[A-Za-z]{0,15}',
           rb'[A-Za-z]{0,10}[Tt]emplate[A-Za-z]{0,15}',
           rb'[A-Za-z]{0,10}[Ss]cenario[A-Za-z]{0,15}',
           rb'[A-Za-z]{0,10}[Pp]ersonal[A-Za-z]{0,15}',
           rb'[A-Za-z]{0,10}[Ee]xtend[A-Za-z]{0,15}[Mm]enu[A-Za-z]{0,10}',
           rb'[Cc]loud[Ss]ync[A-Za-z]{0,10}',
           rb'[Cc]ompatible[A-Za-z]{0,15}',
           rb'[Ll]ogin[A-Za-z]{0,10}[Cc]ompat']:
    for m in re.finditer(kw, data):
        # get full null-terminated string
        b = m.start()
        while b > 0 and 32 <= data[b-1] < 127: b -= 1
        e = m.end()
        while e < len(data) and 32 <= data[e] < 127: e += 1
        st = data[b:e].decode('ascii','replace')
        if st not in seen and len(st) < 80:
            seen.add(st)
            rva = off2rva(b)
            if rva and rva > 0x24E000:  # rdata only
                print(f"  @0x{rva:X}: {st[:75]}")
