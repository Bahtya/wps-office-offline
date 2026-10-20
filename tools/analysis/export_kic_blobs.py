# KEY FINDING: compatible_type is NOT in the current registry dump!
# Wait - we set it earlier but the full restore must have cleared it.
# Let me re-check and also verify the complete solution.
#
# Actually looking at the dump again - compatible_type IS missing from this output.
# But earlier we verified it was set and working. Let me check directly.
#
# THE REAL ANSWER for scripting:
#
# 1. compatible_type = 1 (plain DWORD at Common) -> offline login bypass
# 2. The 功能定制 checkboxes write to kic\switch\user (encrypted)
#    BUT the settings ALSO get mirrored somewhere readable.
#
# 3. THE SIMPLEST APPROACH: ksomisc settings dialog is a Qt app.
#    When you click OK, it writes to kic + also broadcasts a change notification.
#    We can achieve the same by:
#    a) Writing compatible_type=1 (the critical one, already proven)
#    b) For the checkbox settings: export/import the kic\switch registry values
#       as "known-good blobs" that we transplant on fresh installs
#    c) The encrypted values are deterministic (same input = same output)
#
# Let me verify: export current kic\switch values as a transplant-ready blob

import winreg, json, base64

# Export the working state
result = {"user": {}, "notify": {}}
for subkey in ["user", "notify"]:
    path = rf"Software\Kingsoft\Office\6.0\Common\kic\switch\{subkey}"
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, path)
        i = 0
        while True:
            try:
                name, value, typ = winreg.EnumValue(key, i)
                result[subkey][name] = {"value": value, "type": typ}
                i += 1
            except OSError:
                break
        winreg.CloseKey(key)
    except FileNotFoundError:
        pass

print(json.dumps(result, indent=2, ensure_ascii=False))

# Save as importable .reg file
reg_content = "Windows Registry Editor Version 5.00\r\n\r\n"
reg_content += "[HKEY_CURRENT_USER\\Software\\Kingsoft\\Office\\6.0\\Common\\kic\\switch\\user]\r\n"
for name, info in result["user"].items():
    reg_content += f'"{name}"="{info["value"]}"\r\n'
reg_content += "\r\n[HKEY_CURRENT_USER\\Software\\Kingsoft\\Office\\6.0\\Common\\kic\\switch\\notify]\r\n"
for name, info in result["notify"].items():
    reg_content += f'"{name}"="{info["value"]}"\r\n'

with open(r"C:\Users\1531\Documents\project\re-wps\tools\patches\kic_switches_working.reg", "w", encoding="utf-16-le") as f:
    f.write("\ufeff" + reg_content)

print("\n\nSaved to tools/patches/kic_switches_working.reg")
print(f"Total: {len(result['user'])} user switches, {len(result['notify'])} notify switches")
