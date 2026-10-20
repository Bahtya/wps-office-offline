
let paintEvent = Process.getModuleByName('kprometheus.dll').getExportByName('?paintEvent@KPromeHeaderAvatar@@MEAAXPEAVQPaintEvent@kso_qt@@@Z');
let hideAddr = null;
for (const n of ['?hide@QWidget@kso_qt@@QEAAXXZ', '?setVisible@QWidget@kso_qt@@UEAAX_N@Z']) {
  try { hideAddr = Module.getExportByName(null, n); send('found ' + n + ' @' + hideAddr); break; } catch(e) {}
}
send('paint=' + paintEvent + ' hide=' + hideAddr);
let hidden = false;
Interceptor.attach(paintEvent, {
  onEnter(args) {
    if (hidden) return;
    hidden = true;
    const w = this.context.rcx;
    send('this=' + w);
    if (hideAddr) {
      const f = new NativeFunction(hideAddr, 'void', ['pointer', 'bool']);
      f(w, false);
      send('HIDDEN');
    }
  }
});
send('ready');
