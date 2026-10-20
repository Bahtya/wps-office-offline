# CRITICAL FINDING:
# k0 XOR k7 = 524278fbd733f2522800e1e441996da2 + 16 ZERO bytes
# k0 XOR k6 also has 16 zero bytes at positions 16-31
#
# This means k0, k6, k7 share IDENTICAL bytes from position 16 to 31.
# That's a full AES block (16 bytes) of identical ciphertext.
# In AES-ECB, identical ciphertext block = identical plaintext block.
#
# The first 16 bytes differ (different switch names).
# The second block (bytes 16-31) is the same = same plaintext in second block.
# This is consistent with AES-ECB where:
#   block1 = encrypt(name_bytes[0:16])
#   block2 = encrypt(name_bytes[16:32])  <- same suffix for all _shellext names
#
# CONCLUSION: This is AES-ECB (or similar block cipher in ECB mode).
# We CANNOT derive the key without extracting it from the binary.
#
# PRACTICAL SOLUTION: Don't crack the crypto. Instead:
# 1. Use Frida to hook the ENCRYPTION function in a running WPS process
# 2. Feed it our known switch names and capture the encrypted output
# 3. Or better: use Frida to hook the DECRYPTION and call it with our known
#    plaintext to establish the name->ciphertext mapping
#
# EVEN BETTER: We already have a UNIVERSAL approach that doesn't need crypto:
# The ksomisc.exe tool itself can be automated! We showed it can be driven
# by UI automation. But that requires a running GUI.
#
# MOST PRACTICAL UNIVERSAL APPROACH:
# Write a small helper that:
# 1. Launches ksomisc.exe in background
# 2. Uses Windows UI Automation to toggle all checkboxes
# 3. Clicks OK
# 4. Closes ksomisc
# This works on ANY machine because ksomisc does the encryption natively.
#
# Let me also check if there's a COMMAND LINE interface we missed.

import subprocess, os

ksomisc = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\ksomisc.exe"
# Check for embedded command-line strings
data = open(ksomisc, 'rb').read()
import re
print("=== Command-line argument strings ===")
for m in re.finditer(rb'[-/][a-zA-Z]{1,12}(?:\s|[\x00])', data[:0x250000]):
    s = m.group().decode('ascii','replace').strip()
    if s and s not in ('-', '--') and len(s) > 2:
        # check context
        ctx_start = max(0, m.start()-30)
        ctx = data[ctx_start:m.end()+30]
        # only print if in .text (function reference area)
        if m.start() < 0x24D400:  # .text section
            print(f"  {s} @0x{m.start():X}")

# Check for IPC named pipe or COM interface
print("\n=== IPC/COM strings ===")
for kw in [rb'\\\\\.\\pipe\\[\x20-\x7e]{3,40}', rb'CreateNamedPipe', rb'CoCreateInstance',
           rb'CommandLineToArgvW', rb'GetCommandLineW']:
    for m in re.finditer(kw, data):
        b = m.start()
        while b > 0 and 32 <= data[b-1] < 127: b -= 1
        e = m.end()
        while e < len(data) and 32 <= data[e] < 127: e += 1
        print(f"  {data[b:e].decode('ascii','replace')[:60]}")
