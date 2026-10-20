# The critical insight: getFuncSwitchState calls internal function 0x67230
# which likely reads from KIC or the kccsdkpriortydb (mdbx).
#
# Instead of cracking the encryption, take the PRAGMATIC approach:
# ksomisc writes its settings when you click OK. We already KNOW from the
# registry diff that the writes go to kic\switch\user (encrypted).
#
# BUT: there's a much simpler path we haven't tried:
# The kccsdkpriortydb (mdbx.dat) at:
#   %APPDATA%\Kingsoft\wps\addons\data\win-x64\kconfigcenter\kccsdkdb\kccsdkpriortydb\mdbx.dat
# is the LOCAL config database. The KIC system reads from it.
#
# Even simpler: ksomisc.exe supports COMMAND-LINE or IPC to apply settings!
# Let me check for command line arguments, or find how the settings dialog
# communicates changes to the main WPS process.
#
# Most practical approach: reverse the KIC encryption to write directly.

# First: find the encryption by looking at what happens between checkbox click
# and registry write. The kic\switch values are base64 encoded.
# Check if there's a simpler encoding: maybe it's just base64(xor(plaintext, key))

import base64
import struct

# Known kic\switch\user values (from earlier registry export)
values = {
    "6yNvOS114l8rSL+kOuqwC0F1uYEKqK0txnQophtU3m4=": "xlZOQzhROYa7Ns4FrEvF6A==",
    "jTQDZ60PH0TgGVc5XPR/PU7FlhQ8sfv+Ir0usxuF3ZU=": "YZscsn8bxIUA/8MPy0iLKg==",
    "qA32MuVupIR0D+2e/hYicA==": "9+Fvo/WOggUJB2w4V258iA==",
    "qssOqcEcuBksgfkgNmgDpW3dpPs4ssTllPQRRIC7smA=": "SUEs1O3x3YlFcRHbjuXQ7w==",
    "acDkBNIdhqvnq4dBKpXAHPoIu0Zp53bEPEBHr+J7KWE=": "5Kpiv6MoUVTkvQo1da+BDg==",
}

# Try: base64 decode and look for patterns
print("=== Decoded switch values ===")
for k, v in values.items():
    kd = base64.b64decode(k)
    vd = base64.b64decode(v)
    print(f"key({len(kd)}B): {kd.hex()}")
    print(f"val({len(vd)}B): {vd.hex()}")
    print()

# Check: is key 32 bytes (SHA256 of name)? Values are 16 bytes (2 AES blocks? or hash?)
# If key = SHA256(setting_name), we can compute it for known names!
import hashlib
test_names = [
    "type.scene_recommend", "type.template", "type.online_template",
    "type.vas_shellext", "type.cloud_shellext", "type.wpsai_shellext",
    "type.edit_shellext", "type.freediskspace_shellext",
    "compatible_type", "CommonVipTab",
]
print("=== SHA256 of known setting names ===")
for name in test_names:
    h = hashlib.sha256(name.encode()).digest()
    b64 = base64.b64encode(h).decode()
    print(f"  {name}: {b64}")
    # check if any existing key matches
    for k in values:
        if k == b64:
            print(f"    *** MATCHES existing key! ***")
