// Live-hide: paintEvent hook -> hide@QWidget from kprometheus exports
const kp = Process.findModuleByName('kprometheus.dll');
if (!kp) { send('NOBASE'); }
else {
  let paintEvent = null, hideAddr = null;
  const exps = Process.getModuleByName('kprometheus.dll').enumerateExports();
  for (const e of exps) {
    if (e.name.indexOf('paintEvent@KPromeHeaderAvatar') >= 0) paintEvent = e.address;
    if (e.name === '?hide@QWidget@kso_qt@@QEAAXXZ') hideAddr = e.address;
  }
  send('paintEvent=' + paintEvent + ' hide=' + hideAddr);
  let hidden = false;
  Interceptor.attach(paintEvent, {
    onEnter(args) {
      if (hidden) return;
      hidden = true;
      const w = this.context.rcx;
      send('paintEvent this=' + w);
      const hide = new NativeFunction(hideAddr, 'void', ['pointer']);
      hide(w);
      send('HIDE CALLED');
    }
  });
  send('ready');
}
