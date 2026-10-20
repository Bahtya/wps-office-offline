
const ks = Process.findModuleByName('ksolite.dll');
let paintEvent = Process.getModuleByName('kprometheus.dll').getExportByName('?paintEvent@KPromeHeaderAvatar@@MEAAXPEAVQPaintEvent@kso_qt@@@Z');
let hideAddr = ks.getExportByName('?hide@QWidget@kso_qt@@QEAAXXZ');
send('paint=' + paintEvent + ' hide=' + hideAddr);
let done = false;
Interceptor.attach(paintEvent, {
  onEnter(args) {
    if (done) return;
    done = true;
    const w = this.context.rcx;
    send('this=' + w);
    const hide = new NativeFunction(hideAddr, 'void', ['pointer']);
    hide(w);
    send('HIDDEN');
  }
});
send('ready');
