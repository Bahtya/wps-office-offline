import re, os
os.chdir(r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6")
ident = re.compile(rb'[A-Za-z0-9_\\/:.\-]{4,90}')
kws = (b'login', b'Login', b'qing', b'Qing', b'promot', b'Promot')
for f in ['kshell.dll', 'ksolite.dll', 'kso.dll']:
    data = open(f, 'rb').read()
    found = set()
    for m in ident.finditer(data):
        s = m.group(0)
        if not any(k in s for k in kws):
            continue
        t = s.decode(errors='ignore')
        low = t.lower()
        if ('\\' in t or '/' in t
                or low.startswith(('is', 'need', 'show', 'hide', 'no', 'enable', 'disable', 'get', 'set'))):
            found.add(t)
    print(f'== {f} ==')
    for s in sorted(found)[:40]:
        print('  ', s)
