# The kconfigcentersdk addon has kconfigcentersdk.dll. Let me check its exports
# AND find the mdbx write mechanism.
#
# BUT actually, the simplest path I haven't fully explored:
# ksomisc.exe is a standalone tool. When you check boxes and click OK,
# it writes directly. Let me find what it actually writes by:
# 1. Checking the kconfigcentersdk.dll exports
# 2. Or better: instrument ksomisc with Frida to watch RegSetValueExW calls
#
# Actually even simpler: check if the settings dialog has a "APPLY" or "WRITE"
# that goes to a DIFFERENT plain-text registry location that we missed.
# We already know compatible_type goes to HKCU\...\Common as plain DWORD.
# Maybe the other settings also have plain-text fallbacks!

# Let me check: what are the ACTUAL current values in kic\switch\user now
# (after we manually checked everything) vs what we need?
import subprocess, winreg

key_path = r"Software\Kingsoft\Office\6.0\Common\kic\switch\user"
try:
    key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path)
    i = 0
    while True:
        try:
            name, value, typ = winreg.EnumValue(key, i)
            print(f"  [{typ}] {name} = {value}")
            i += 1
        except OSError:
            break
    winreg.CloseKey(key)
except FileNotFoundError:
    print("kic\\switch\\user not found")

print("\n=== kic\\switch\\notify ===")
key_path2 = r"Software\Kingsoft\Office\6.0\Common\kic\switch\notify"
try:
    key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path2)
    i = 0
    while True:
        try:
            name, value, typ = winreg.EnumValue(key, i)
            print(f"  [{typ}] {name} = {value}")
            i += 1
        except OSError:
            break
    winreg.CloseKey(key)
except FileNotFoundError:
    print("kic\\switch\\notify not found")

# Check compatible_type current value
print("\n=== compatible_type ===")
try:
    key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Kingsoft\Office\6.0\Common")
    val, typ = winreg.QueryValueEx(key, "compatible_type")
    print(f"  compatible_type = {val} (type {typ})")
    winreg.CloseKey(key)
except FileNotFoundError:
    print("  not found")
