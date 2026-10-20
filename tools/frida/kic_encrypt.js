// Universal KIC switch encryption: call gpcrypt::Encode from live process
// to convert known type.* names to encrypted registry keys on ANY machine.
const krt = Process.findModuleByName('krt.dll');
if (!krt) { send('NO krt.dll'); }
else {
  let encodeAddr = null, encryptAddr = null;
  const exps = krt.enumerateExports();
  send('krt exports: ' + exps.length);
  for (const e of exps) {
    if (e.name.indexOf('Encode@gpcrypt') >= 0) { encodeAddr = e.address; send('gpcrypt::Encode @ ' + e.address); }
    if (e.name.indexOf('encrypt@KDES') >= 0) { encryptAddr = e.address; send('KDES::encrypt @ ' + e.address); }
  }

  const switchNames = [
    'type.scene_recommend', 'type.template', 'type.online_template',
    'type.vas_shellext', 'type.cloud_shellext', 'type.compress_shellext',
    'type.desktop_shellext', 'type.recyclerecovery_shellext',
    'type.freediskspace_shellext', 'type.wpsai_shellext',
    'type.edit_shellext', 'type.vas_shellnewext',
  ];

  // gpcrypt::Encode(const QString &input, QByteArray &output) -> bool
  // QString is a Qt type: d-pointer to QStringData
  // QByteArray: { char *data; int size; }
  // We need to construct a QString. Qt5 QString layout:
  //   [ref(4) size(4) alloc(4)+reserved(4) offset(4)... data at +12 or via d->data]
  // Simpler: use KDES::encrypt which has same signature.
  //
  // Actually easier approach: hook getFuncSwitchState (which we know works) and
  // let it decrypt existing values. But we want ENCRYPTION.
  //
  // gpcrypt::Encode(QString, QByteArray*) - we need a QString.
  // Qt5 QString can be constructed from const char* via QString::fromUtf8
  // which is available in Qt5CoreKso.dll.

  const qtcore = Process.findModuleByName('Qt5CoreKso.dll');
  if (!qtcore) { send('NO Qt5CoreKso'); }
  else {
    let fromUtf8 = null;
    const qexps = qtcore.enumerateExports();
    for (const e of qexps) {
      if (e.name.indexOf('fromUtf8@QString') >= 0 && e.name.indexOf('PEBD') >= 0) {
        fromUtf8 = e.address;
        send('QString::fromUtf8 @ ' + e.address + ' : ' + e.name);
        break;
      }
    }
    if (!fromUtf8) {
      // try alternate name
      for (const e of qexps) {
        if (e.name.indexOf('fromUtf8@QString') >= 0) {
          fromUtf8 = e.address;
          send('QString::fromUtf8(alt) @ ' + e.address + ' : ' + e.name);
          break;
        }
      }
    }

    if (encodeAddr && fromUtf8) {
      // Test with one name first
      const testName = switchNames[0];
      send('Testing with: ' + testName);

      // Allocate QString (just a pointer, 8 bytes)
      const qsPtr = Memory.alloc(8);
      const fromUtf8Fn = new NativeFunction(fromUtf8, 'pointer', ['pointer', 'int']);
      // fromUtf8(const char *str, int size) returns QString by value
      // In MSVC x64, QString return by value uses hidden return pointer
      // Actually QString is a single pointer, so it's returned in rax

      const nameBuf = Memory.allocAnsiString(testName);
      const qs = fromUtf8Fn(nameBuf, testName.length);
      send('QString created: ' + qs);

      // Allocate QByteArray (pointer to data + int size) - just pointer
      const baPtr = Memory.alloc(8);

      // Call Encode(const QString &input, QByteArray &output)
      // args: rcx = &QString, rdx = &QByteArray
      const encodeFn = new NativeFunction(encodeAddr, 'bool', ['pointer', 'pointer']);
      const result = encodeFn(qs, baPtr);
      send('Encode returned: ' + result);

      // Read QByteArray result
      const baData = baPtr.readPointer();
      const baSize = baPtr.add(8).readS32();
      send('QByteArray: size=' + baSize);

      if (baSize > 0 && baSize < 200) {
        const bytes = baData.readByteArray(baSize);
        send('ENCODED: ' + hexdump(bytes, {length: baSize}));
        // Convert to base64 for registry
        // Frida doesn't have base64, send raw and process outside
        const arr = new Uint8Array(bytes);
        let hex = '';
        for (let i = 0; i < arr.length; i++) hex += ('0' + arr[i].toString(16)).slice(-2);
        send('HEX:' + hex);
      }
    } else {
      send('Missing: encode=' + encodeAddr + ' fromUtf8=' + fromUtf8);
    }
  }
}
