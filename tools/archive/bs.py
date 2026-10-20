"""State-tracked bisection: maintains quar_state.json = list of quarantined entries."""
import os, re, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bisect import QUAR

TOOLS = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(TOOLS, 'quar_state.json')
BS = chr(92)
PAT = re.compile('[:' + re.escape(BS) + ']+')

def entry_for(p):
    return PAT.sub('_', p)

def orig(e):
    return e[0] + ':' + BS + e[1:].replace('_', BS)

def load():
    return json.load(open(STATE))

def save(lst):
    json.dump(sorted(lst), open(STATE, 'w'), indent=0)

def move_to_quar(entries):
    import shutil
    cur = set(load())
    for e in entries:
        src, dst = orig(e), os.path.join(QUAR, e)
        if os.path.exists(dst) or not os.path.exists(src):
            continue
        shutil.move(src, dst)
        cur.add(e)
    save(cur)
    return len(cur)

def move_back(entries):
    import shutil
    cur = set(load())
    for e in entries:
        src, dst = os.path.join(QUAR, e), orig(e)
        if not os.path.exists(src) or os.path.exists(dst):
            cur.discard(e)
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.move(src, dst)
        cur.discard(e)
    save(cur)
    return len(cur)

if __name__ == '__main__':
    cmd = sys.argv[1]
    was = set()
    for fn in ('batchA.txt', 'batchB.txt', 'batchC.txt'):
        was |= {l.strip() for l in open(os.path.join(TOOLS, fn)) if l.strip()}
    universe = sorted(was)
    if cmd == 'reset':
        save([])
        print('state reset; quar dir entries:', os.listdir(QUAR))
    elif cmd == 'q':
        n = int(sys.argv[2])
        cur = set(load())
        pool = [e for e in universe if e not in cur and os.path.exists(orig(e))]
        sel = pool[:n]
        total = move_to_quar(sel)
        print('quarantined', len(sel), 'total now', total)
    elif cmd == 'r':
        n = int(sys.argv[2])
        cur = sorted(load())
        # restore the LAST n quarantined (LIFO) or first n with arg 'first'
        which = sys.argv[3] if len(sys.argv) > 3 else 'last'
        sel = cur[:n] if which == 'first' else cur[-n:]
        move_back(sel)
        print('restored', len(sel), 'total now', len(load()))
    elif cmd == 'status':
        cur = load()
        print('state count:', len(cur))
        print('quar dir  :', len(os.listdir(QUAR)))
