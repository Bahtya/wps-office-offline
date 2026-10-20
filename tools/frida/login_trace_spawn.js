// Startup trace of the login decision chain in wps.exe (editor process)
const mods0 = Process.enumerateModules();
function baseOf(n) { const m = mods0.find(m => m.name.toLowerCase() === n.toLowerCase()); return m ? m.base : null; }
function mkSym() {
  const mods = Process.enumerateModules();
  return function (a) {
    const m = mods.find(m => a.compare(m.base) >= 0 && a.compare(m.base.add(m.size)) < 0);
    return m ? (m.name + '+0x' + a.sub(m.base).toString(16)) : a.toString();
  };
}
const sym = mkSym();

function waitHook(modName, rva, name, dumpField) {
  const t0 = Date.now();
  const iv = setInterval(() => {
    const b = baseOf(modName);
    if (!b) {
      if (Date.now() - t0 > 25000) { clearInterval(iv); send('TIMEOUT waiting ' + modName); }
      return;
    }
    clearInterval(iv);
    try {
      Interceptor.attach(b.add(rva), {
        onEnter(args) { this.self = args[0]; this.ra = this.returnAddress; },
        onLeave(rv) {
          let extra = '';
          if (dumpField !== undefined) {
            try { extra = ' self[' + dumpField.toString(16) + ']=' + this.self.add(dumpField).readU8(); } catch (e) {}
          }
          send('CALL ' + name + ' ret=' + rv.toInt32() + extra + ' <- ' + sym(this.ra));
        }
      });
      send('HOOKED ' + name + ' @ ' + modName + '+0x' + rva.toString(16));
    } catch (e) { send('HOOKFAIL ' + name + ': ' + e); }
  }, 50);
}

waitHook('ksolite.dll', 0x2257D0, 'isLogined', 0x16c);
waitHook('ksolite.dll', 0x2256F0, 'isEnableForceLogin', undefined);
waitHook('ksolite.dll', 0x31fac0, 'isLogined-inner(0x31fac0)', undefined);
waitHook('ksolite.dll', 0x222210, 'getLastUserLoginInfo', undefined);
waitHook('ksolite.dll', 0x2222D0, 'getLoginInfoIpcRes', undefined);
waitHook('ksolite.dll', 0x34EA0, 'loginStatusChanged', undefined);
waitHook('ksolite.dll', 0x34E60, 'KAccountSdkProxy::loginInfoChanged', undefined);
waitHook('ksolite.dll', 0x44800, 'KAccountSdkProxy::connectToLoginInfoChanged', undefined);
send('SPAWN TRACE READY');
