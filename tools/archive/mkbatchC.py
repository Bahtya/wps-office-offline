import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bisect import requarantine, kill_wps, smoke, QUAR

def entry_for(path):
    return re.sub(r'[:\\]+', '_', path)

OFFICE = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158"
addons = os.path.join(OFFICE, 'office6', 'addons')

done = set()
for f in ('batchA.txt', 'batchB.txt'):
    done |= {l.strip() for l in open(os.path.join(os.path.dirname(os.path.abspath(__file__)), f))}

rest = [entry_for(os.path.join(addons, d)) for d in sorted(os.listdir(addons))
        if os.path.isdir(os.path.join(addons, d))]
rest = [e for e in rest if e not in done]
print('remaining addon dirs to requar:', len(rest))
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'batchC.txt'), 'w').write('\n'.join(rest))
if sys.argv[1:2] == ['apply']:
    kill_wps()
    requarantine(rest)
    print('batchC requarantined')
