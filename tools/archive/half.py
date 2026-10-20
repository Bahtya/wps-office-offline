"""Halving bisection driver: quarantine half of previously-removed items still present."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bisect import requarantine

TOOLS = os.path.dirname(os.path.abspath(__file__))
OFFICE = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158"
BS = chr(92)
PATTERN = re.compile('[:' + re.escape(BS) + ']+')

def entry_for(p):
    return PATTERN.sub('_', p)

was = set()
for fn in ('batchA.txt', 'batchB.txt', 'batchC.txt'):
    was |= {l.strip() for l in open(os.path.join(TOOLS, fn)) if l.strip()}

def orig(e):
    return e[0] + ':' + BS + e[1:].replace('_', BS)

present = sorted(e for e in was if os.path.exists(orig(e)))
half = int(sys.argv[1]) if len(sys.argv) > 1 else len(present) // 2
sel = present[:half]
print('present-was-quarantined:', len(present), '-> quarantining first', len(sel))
requarantine(sel)
