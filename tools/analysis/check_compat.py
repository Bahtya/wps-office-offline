# Verify compatible_type is still set (it's the critical one)
import winreg
try:
    key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Kingsoft\Office\6.0\Common")
    val, typ = winreg.QueryValueEx(key, "compatible_type")
    print(f"compatible_type = {val} (type {typ})")
    winreg.CloseKey(key)
except FileNotFoundError:
    print("compatible_type NOT SET - need to re-apply!")
