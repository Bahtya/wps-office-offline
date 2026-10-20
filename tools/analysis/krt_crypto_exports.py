# ksomisc has no useful CLI. The universal approach is to:
# 1. Use Frida to call the ENCRYPTION function from a live WPS process
#    (the krt.dll encryption is available in-process)
# 2. Feed it each type.* name and capture the encrypted output
# 3. Write the results directly to registry
#
# But there's an EVEN SIMPLER universal approach:
# The kic\switch encryption uses AES with a key embedded in the binary.
# Since krt.dll contains both AES sbox AND SHA256 constants, the key is
# derived from a fixed string in the binary.
#
# For UNIVERSALITY, the best approach is:
# Write a Frida script that:
#   a) Attaches to a running wps.exe
#   b) Finds the encryption function via krt.dll exports
#   c) Calls it with each type.* name
#   d) Writes results to registry
#
# Let me find the actual encryption function signature in krt.dll.

import pefile, re, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_64

KRT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\krt.dll"
data = open(KRT, 'rb').read()
pe = pefile.PE(KRT, fast_load=True)
pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
secs = [(s.VirtualAddress, s.Misc_VirtualSize, s.PointerToRawData, s.Name.decode().strip()) for s in pe.sections]
def rva2off(rva):
    for va, vs, raw, name in secs:
        if va <= rva < va + vs: return rva - va + raw

# List all exports with 'encrypt' 'decrypt' 'cipher' 'aes' 'hash' 'encode'
print("=== krt.dll crypto exports ===")
exp = pe.DIRECTORY_ENTRY_EXPORT
for s in exp.symbols:
    if s.name:
        n = s.name.decode()
        if any(k in n.lower() for k in ['encrypt', 'decrypt', 'cipher', 'aes', 'encode', 'base64', 'kic', 'switch']):
            print(f"  RVA 0x{s.address:X}: {n[:75]}")

# Also look for setSwitch (the writer!)
print("\n=== krt.dll set/write exports ===")
for s in exp.symbols:
    if s.name:
        n = s.name.decode()
        if any(k in n.lower() for k in ['set', 'write', 'save', 'put', 'update', 'store']):
            print(f"  RVA 0x{s.address:X}: {n[:75]}")
