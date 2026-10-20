"""Quarantine <-> original-path mover for WPS debloat bisection."""
import os, re, shutil, sys, subprocess

QUAR = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\_quarantine"

def orig_path(entry: str) -> str:
    m = re.match(r'^([A-Za-z])_(.*)$', entry)
    return m.group(1) + ':\\' + m.group(2).replace('_', '\\')

def entries():
    return sorted(os.listdir(QUAR))

def addon_entries():
    return [e for e in entries() if '_addons_' in e]

def restore(lst):
    for e in lst:
        if e.startswith('C_Program Files'):
            continue  # 需管理员且与编辑器加载无关, 还原脚本另行处理
        src = os.path.join(QUAR, e)
        dst = orig_path(e)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.exists(dst):
            print('SKIP exists:', dst); continue
        shutil.move(src, dst)

def requarantine(lst):
    for e in lst:
        dst = orig_path(e)
        src = os.path.join(QUAR, e)
        if os.path.exists(src):
            print('SKIP already quarantined:', e); continue
        if not os.path.exists(dst):
            print('SKIP missing:', dst); continue
        shutil.move(dst, src)

def kill_wps():
    subprocess.run(['powershell', '-NoProfile', '-Command',
        "Get-Process wps,et,wpp,wpsoffice,promecefpluginhost,wpscenter -ErrorAction SilentlyContinue | Stop-Process -Force"],
        capture_output=True)

def smoke(tag: str):
    out = rf"C:\Users\1531\Documents\project\re-wps\tools\smoke_{tag}.png"
    subprocess.run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        r"C:\Users\1531\Documents\project\re-wps\tools\smoke.ps1",
        '-Arg', r"C:\Users\1531\Desktop\照片\照片处理工具说明.docx",
        '-OutPng', out, '-WaitSec', '8'], capture_output=True)
    return out

if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'list':
        for e in entries(): print(e)
    elif cmd == 'restore-all':
        restore(entries()); print('restored', len(entries()))
    elif cmd == 'restore-addons':
        lst = sys.argv[2].split(',') if len(sys.argv) > 2 else addon_entries()
        restore(lst); print('restored', len(lst))
    elif cmd == 'requar':
        lst = sys.argv[2].split(',')
        requarantine(lst); print('requarantined', len(lst))
    elif cmd == 'requar-addons':
        lst = sys.argv[2].split(',') if len(sys.argv) > 2 else addon_entries()
        requarantine(lst); print('requarantined', len(lst))
    elif cmd == 'smoke':
        kill_wps(); print(smoke(sys.argv[2] if len(sys.argv) > 2 else 't'))
    elif cmd == 'kill':
        kill_wps()
