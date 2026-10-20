# PERFECT FINDING: krt.dll reads from "Software\Kingsoft\Office\6.0\Common" (PLAIN!)
# and "Software\Kingsoft\Office\6.0\Common\Local" and "Custom Application Settings"
#
# This means the getFuncSwitchState ultimately reads from PLAIN REGISTRY values
# under HKCU\Software\Kingsoft\Office\6.0\Common! 
# The kic\switch encrypted values are probably a CLOUD SYNC layer on top.
# The LOCAL read path is plain registry!
#
# Now: what VALUE NAME does it look for? The type.* strings (type.scene_recommend etc.)
# Let me verify by checking if those exist in the current registry.

import winreg

base = r"Software\Kingsoft\Office\6.0\Common"
for subkey in ["", r"\Local", r"\Custom Application Settings"]:
    path = base + subkey
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, path)
        count = winreg.QueryInfoKey(key)[1]
        print(f"\n=== {path} ({count} values) ===")
        for i in range(min(count, 50)):
            try:
                name, val, typ = winreg.EnumValue(key, i)
                print(f"  [{typ}] {name} = {val}")
            except OSError:
                break
        winreg.CloseKey(key)
    except FileNotFoundError:
        print(f"\n=== {path} === NOT FOUND")

# Also check the parent key with the type.* names
print("\n=== Search for type.* values anywhere under Common ===")
def search_tree(path, depth=0):
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, path)
        # enumerate values
        count = winreg.QueryInfoKey(key)[1]
        for i in range(count):
            try:
                name, val, typ = winreg.EnumValue(key, i)
                if 'type.' in name.lower() or 'recommend' in name.lower() or 'shellext' in name.lower():
                    print(f"  {'  '*depth}{path}\\{name} = {val}")
            except OSError:
                break
        # enumerate subkeys
        subcount = winreg.QueryInfoKey(key)[0]
        for i in range(subcount):
            try:
                subname = winreg.EnumKey(key, i)
                search_tree(path + "\\" + subname, depth + 1)
            except OSError:
                break
        winreg.CloseKey(key)
    except FileNotFoundError:
        pass

search_tree(r"Software\Kingsoft\Office\6.0")
