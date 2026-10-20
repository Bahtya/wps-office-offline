// Trace WPS login state machine — real return values at runtime (compat API)
const mods = Process.enumerateModules();
function baseOf(n) {
  const m = mods.find(m => m.name.toLowerCase() === n.toLowerCase());
  return m ? m.base : null;
}
function symOf(a) {
  const m = mods.find(m => a.compare(m.base) >= 0 && a.compare(m.base.add(m.size)) < 0);
  return m ? (m.name + '+0x' + a.sub(m.base).toString(16)) : a.toString();
}
const counts = {};
function hook(mod, rva, name, dumpField) {
  const base = baseOf(mod);
  if (!base) { send('NOBASE ' + mod); return; }
  const addr = base.add(rva);
  Interceptor.attach(addr, {
    onEnter(args) { this.self = args[0]; this.ra = this.returnAddress; },
    onLeave(rv) {
      counts[name] = (counts[name] || 0) + 1;
      if (counts[name] > 30) return;
      let extra = '';
      if (dumpField !== undefined) {
        try { extra = ' self[' + dumpField.toString(16) + ']=' + this.self.add(dumpField).readU8(); } catch (e) { extra = ' self?'; }
      }
      send('CALL ' + name + ' ret=' + rv.toInt32() + extra + ' <- ' + symOf(this.ra));
    }
  });
  send('HOOKED ' + name + ' @ ' + mod + '+0x' + rva.toString(16));
}

hook('ksolite.dll', 0x2257D0, 'KCloudSvrProxy::isLogined', 0x16c);
hook('ksolite.dll', 0x2256F0, 'KCloudSvrProxy::isEnableForceLogin', undefined);
hook('ksolite.dll', 0x2223A0, 'KCloudSvrProxy::getLoginInfoMap', undefined);
hook('ksolite.dll', 0x2222D0, 'KCloudSvrProxy::getLoginInfoIpcRes', undefined);
hook('ksolite.dll', 0x222210, 'KCloudSvrProxy::getLastUserLoginInfo', undefined);
hook('ksolite.dll', 0x34EA0, 'KCloudSvrProxy::loginStatusChanged', undefined);
hook('kshell.dll', 0x55B400, 'KxApplication::IsStartUpInForceLoginMode', undefined);
send('ALL HOOKS INSTALLED');
