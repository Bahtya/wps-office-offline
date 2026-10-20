
const ks = Process.findModuleByName('ksolite.dll');
send('ksolite base=' + ks.base + ' size=' + ks.size);
let exps = [];
try { exps = ks.enumerateExports(); send('enumExports count=' + exps.length); } catch(e) { send('enum err: ' + e); }
let hideAddr = null;
for (const e of exps) {
  if (e.name === '?hide@QWidget@kso_qt@@QEAAXXZ') { hideAddr = e.address; send('FOUND via enum'); break; }
}
if (!hideAddr) {
  try { hideAddr = Module.findExportByName('ksolite.dll', '?hide@QWidget@kso_qt@@QEAAXXZ'); send('findExportByName=' + hideAddr); } catch(e) { send('fnb err ' + e); }
}
let paintEvent = Process.getModuleByName('kprometheus.dll').getExportByName('?paintEvent@KPromeHeaderAvatar@@MEAAXPEAVQPaintEvent@kso_qt@@@Z');
send('paint=' + paintEvent);
let done = false;
if (hideAddr) {
  Interceptor.attach(paintEvent, {
    onEnter(args) {
      if (done) return;
      done = true;
      const w = this.context.rcx;
      const hide = new NativeFunction(hideAddr, 'void', ['pointer']);
      hide(w);
      send('HIDDEN ' + w);
    }
  });
  send('armed');
} else { send('NO HIDE EXPORT - giving up'); }
