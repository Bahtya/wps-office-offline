// Trace KicSettings/KicWrapper vtable calls in ksolite: log QString arg + caller
const mods = Process.enumerateModules();
function baseOf(n) { const m = mods.find(m => m.name.toLowerCase() === n.toLowerCase()); return m ? m.base : null; }
function symOf(a) {
  const m = mods.find(m => a.compare(m.base) >= 0 && a.compare(m.base.add(m.size)) < 0);
  return m ? (m.name + '+0x' + a.sub(m.base).toString(16)) : a.toString();
}
function qstr(p) {
  // Qt5-ish QString: d-ptr at [p]; data starts at +0x14 (utf16), size at +0x4 (ints)
  try {
    const d = p.readPointer();
    if (d.isNull() || d.toInt32() === 0) return null;
    const size = d.add(4).readU32();
    if (size === 0 || size > 256) return null;
    const s = d.add(0x14).readUtf16String(size);
    if (s && /[\x20-\x7e\u4e00-\u9fff]/.test(s)) return s;
  } catch (e) {}
  return null;
}

const base = baseOf('ksolite.dll');
if (!base) { send('NO ksolite'); }
else {
  for (const [vtRva, label] of [[0x7CFE80, 'KicSettings'], [0x7CFE20, 'KicWrapper']]) {
    const vt = base.add(vtRva);
    let n = 0;
    for (let i = 0; i < 12; i++) {
      let fp;
      try { fp = vt.add(i * 8).readPointer(); } catch (e) { break; }
      if (fp.isNull()) break;
      const slot = label + '[' + i + ']@' + symOf(fp);
      try {
        Interceptor.attach(fp, {
          onEnter(args) {
            this.a1 = args[1];
            this.ra = this.returnAddress;
            this.slot = slot;
          },
          onLeave(rv) {
            const name = this.a1 ? qstr(this.a1) : null;
            if (name) {
              send('Q ' + this.slot + ' name=[' + name + '] ret=' + rv.toInt32() + ' <- ' + symOf(this.ra));
            }
          }
        });
        n++;
      } catch (e) { send('hookfail ' + slot); }
    }
    send('HOOKED ' + label + ' slots=' + n);
  }
}
send('READY');
