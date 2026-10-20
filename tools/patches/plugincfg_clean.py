"""WPS 插件池清理 + setupplugin.plg 精简 (只保留仍在位的插件声明)"""
import os, re, shutil, sys

QUAR = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\_quarantine"
OFFICE = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158"
PLG = os.path.join(OFFICE, 'office6', 'setupplugincfg', 'setupplugin.plg')
POOL = r"C:\Users\1531\AppData\Roaming\Kingsoft\wps\addons\pool"

def entry_for(path):
    return os.path.join(QUAR, re.sub(r'[:\\]+', '_', path))

# ---- 1. 云端插件池 -> 隔离区 ----
if os.path.isdir(POOL):
    dst = entry_for(POOL)
    if not os.path.exists(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.move(POOL, dst)
        print('pool -> quarantine:', dst)
    else:
        print('pool already quarantined')
# 重建空池目录, 防止下载器报错
os.makedirs(os.path.join(POOL, 'win-x64'), exist_ok=True)
print('empty pool recreated')

# ---- 2. setupplugin.plg: 删除 name 指向已裁 addon 的条目 ----
addons = set(os.listdir(os.path.join(OFFICE, 'office6', 'addons')))  # 现存 addon
src = open(PLG, encoding='utf-8').read()
bak = PLG + '.korig'
if not os.path.exists(bak):
    open(bak, 'w', encoding='utf-8').write(src)
    print('backup ->', bak)

kept, removed = [], []
def repl(m):
    tag = m.group(0)
    nm = re.search(r'name="([^"]+)"', tag)
    if nm and nm.group(1) not in addons:
        removed.append(nm.group(1))
        return ''
    kept.append(nm.group(1) if nm else '?')
    return tag

out = re.sub(r'<plugin\s[^>]*/>', repl, src)
open(PLG, 'w', encoding='utf-8').write(out)
print('kept plugins:', kept)
print('removed plugins (%d):' % len(removed), sorted(set(removed)))
