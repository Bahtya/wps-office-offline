
let paintEvent = Process.getModuleByName('kprometheus.dll').getExportByName('?paintEvent@KPromeHeaderAvatar@@MEAAXPEAVQPaintEvent@kso_qt@@@Z');
let moveAddr = Process.getModuleByName('kprometheus.dll').getExportByName('?move@QWidget@kso_qt@@QEAAXAEBVQPoint@2@@Z');
send('paint=' + paintEvent + ' move=' + moveAddr);
let done = false;
Interceptor.attach(paintEvent, {
  onEnter(args) {
    if (done) return;
    done = true;
    const w = this.context.rcx;
    send('this=' + w);
    // QPoint is returned by value; build QPoint(-30000,-30000) on stack via QPoint ctor
    // Simpler: resize(w, 0, 0) - use resize@QWidget(QSize). QSize ctor needed too.
    // Even simpler: setVisible via vtable. QWidget vtable: first slot = metaObject...
    // QWidget::setVisible is virtual (UEAAX). Read vtable: [w] = vtable ptr; setVisible at slot index 4? risky.
    // Use move with a QPoint built inline: Qt5 QPoint {int xp, int yp} - no d-ptr.
    // QPoint ctor inline: just two ints. move(const QPoint&) takes ref to 8-byte struct.
    const pt = Memory.alloc(8);
    pt.writeS32(-32000); pt.add(4).writeS32(-32000);
    const move = new NativeFunction(moveAddr, 'void', ['pointer', 'pointer']);
    move(w, pt);
    send('MOVED offscreen');
  }
});
send('ready');
