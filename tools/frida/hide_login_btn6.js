// Final: hide via Qt5WidgetsKso.dll exports
const qw = Process.findModuleByName('Qt5WidgetsKso.dll');
const kp = Process.findModuleByName('kprometheus.dll');
if (!qw || !kp) { send('NOBASE qw=' + qw + ' kp=' + kp); }
else {
  let paintEvent = kp.getExportByName('?paintEvent@KPromeHeaderAvatar@@MEAAXPEAVQPaintEvent@kso_qt@@@Z');
  let hideAddr = null;
  for (const n of ['?hide@QWidget@kso_qt@@QEAAXXZ', '?setVisible@QWidget@kso_qt@@UEAAX_N@Z']) {
    try { hideAddr = qw.getExportByName(n); send('found ' + n); break; } catch (e) { send('miss ' + n); }
  }
  send('paint=' + paintEvent + ' hide=' + hideAddr);
  let done = false;
  Interceptor.attach(paintEvent, {
    onEnter(args) {
      if (done) return;
      done = true;
      const w = this.context.rcx;
      send('this=' + w);
      if (hideAddr) {
        const f = new NativeFunction(hideAddr, 'void', ['pointer', 'bool']);
        f(w, false);
        send('HIDDEN via setVisible');
      }
    }
  });
  send('armed');
}
