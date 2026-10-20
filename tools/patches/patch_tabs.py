# Patch kui/kuip files: hide VIP tab / WPS AI proxy / Docer fake tab
# - CT_WorkSpace (CommonVipTab): add visible="false"
# - KxWpsAIGCProxyCommand (WPS AI tab proxy): add visible="false"
# - KxDocerFakeTabCommand useFakeTab: flip to false
import os, re, shutil

BASE = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\res"
FILES = ["wpsongmani.kui", "etongmani.kui", "wppongmani.kui",
         "wpscommon.kuip", "etcommon.kuip", "wppcommon.kuip"]

for fn in FILES:
    p = os.path.join(BASE, fn)
    if not os.path.exists(p):
        continue
    src = open(p, encoding='utf-8', errors='replace').read()
    orig = src

    # 1. VIP tab: CT_WorkSpace ... idKey="CommonVipTab"
    def vip_repl(m):
        tag = m.group(0)
        if 'visible=' in tag:
            return tag
        return tag.replace('idKey="CommonVipTab"', 'idKey="CommonVipTab" visible="false"', 1)
    src = re.sub(r'<KRbControlCommand[^>]*idKey="CommonVipTab"[^>]*/>', vip_repl, src)

    # 2. WPS AI tab proxy (per-app class names)
    def ai_repl(m):
        tag = m.group(0)
        if 'visible=' in tag:
            return tag
        return tag[:-2] + ' visible="false"/>'
    src = re.sub(r'<KxWp[sp]?AIGCProxyCommand[^>]*(?<!visible="false")/>', ai_repl, src)
    src = re.sub(r'<KxEtAIGCProxyCommand[^>]*/>', ai_repl, src)

    # 3. Docer fake tab
    src = src.replace('useFakeTab="true"', 'useFakeTab="false"')

    if src != orig:
        bak = p + '.korig'
        if not os.path.exists(bak):
            shutil.copyfile(p, bak)
        open(p, 'w', encoding='utf-8').write(src)
        print(f"{fn}: PATCHED")
    else:
        print(f"{fn}: no change")
