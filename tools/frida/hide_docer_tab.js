// Live-hide the docer fake tab (compat API)
const kprom = Process.findModuleByName('kprometheus.dll');
const ksol = Process.findModuleByName('ksolite.dll');
if (!kprom || !ksol) { send('NOBASE'); }
else {
  let setVisible = null;
  const names = [
    '?setVisible@QWidget@kso_qt@@QEAAX_N@Z',
    '?hide@QWidget@kso_qt@@QEAAXXZ',
  ];
  for (const n of names) {
    try { setVisible = Module.getExportByName('ksolite.dll', n); send('export hit: ' + n); break; } catch (e) {}
  }
  if (!setVisible) {
    try {
      const exps = Module.enumerateExports('ksolite.dll');
      send('ksolite exports: ' + exps.length);
      for (const e of exps) {
        if (e.name.indexOf('setVisible@QWidget') >= 0 || e.name.indexOf('?hide@QWidget') >= 0) {
          send('cand: ' + e.name);
          setVisible = e.address;
          break;
        }
      }
    } catch (e) { send('enum failed: ' + e); }
  }
  send('setVisible = ' + setVisible);

  let done = false;
  Interceptor.attach(kprom.base.add(0x371D70), {
    onEnter(args) {
      if (done) return;
      done = true;
      send('drawControl hit: args3=' + args[3] + ' args2=' + args[2]);
      if (setVisible) {
        try {
          const f = new NativeFunction(setVisible, 'void', ['pointer', 'bool']);
          f(args[3], false);
          send('hidden args3');
        } catch (e) { send('c3 fail ' + e); }
      }
    }
  });
  send('hook ready');
}
