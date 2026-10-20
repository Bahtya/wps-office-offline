# Crack the KIC switch encryption by reverse engineering krt.dll
# The getFuncSwitchState calls internal function which reads from kic\switch.
# The encrypted key is 32 bytes (SHA256-like?) and value is 16 bytes.
#
# Approach: Frida hook on krt.dll's getFuncSwitchState to observe the
# encryption/decryption in action - dump the plaintext name and the resulting
# ciphertext to find the algorithm.
#
# But first, let me try a simpler hypothesis: the key might just be
# MD5(name) or MD5(name+salt) or some simple derivation.

import hashlib, base64, struct

# Known pairs (name -> encrypted key from registry)
# We know the switch names from ksomisc strings. Let me try to match them.
existing_keys = [
    "6yNvOS114l8rSL+kOuqwC0F1uYEKqK0txnQophtU3m4=",  # 32B
    "jTQDZ60PH0TgGVc5XPR/PU7FlhQ8sfv+Ir0usxuF3ZU=",  # 32B
    "qA32MuVupIR0D+2e/hYicA==",                       # 16B
    "qssOqcEcuBksgfkgNmgDpW3dpPs4ssTllPQRRIC7smA=",  # 32B
    "acDkBNIdhqvnq4dBKpXAHPoIu0Zp53bEPEBHr+J7KWE=",  # 32B
    "6GjQUxiYYdH8NxOVJUdpOAjJeIHv/0n3dzAUyF0tGYo=",  # 32B
    "VSXFEuhyZ+7MHjXCpG0+tBIZpYyWuOAgJbjlxkCYroM=",  # 32B
    "uWEXwvpGEA0DSF5Ae3PdqUF1uYEKqK0txnQophtU3m4=",  # 32B (ends same as 1st!)
    "kaQm19O36bskO7uwj2PeAJN5951KEClWCpFJR5RHyJs=",  # 32B
    "PMMpgkp8ls/4qfEiWKL9gvL4eyv2r9wg2ea0HbDpK48=",  # 32B
    "pyoJeTexMJjB7c+B5ylpHt+wVeomk+s2MWuw1Y4FoIg=",  # 32B
]

known_names = [
    "type.scene_recommend",
    "type.template",
    "type.online_template",
    "type.vas_shellext",
    "type.cloud_shellext",
    "type.compress_shellext",
    "type.desktop_shellext",
    "type.recyclerecovery_shellext",
    "type.freediskspace_shellext",
    "type.wpsai_shellext",
    "type.edit_shellext",
    "type.vas_shellnewext",
]

print("=== Testing hash hypotheses ===")
hypotheses = {
    "md5": lambda n: hashlib.md5(n.encode()).digest(),
    "sha1_16": lambda n: hashlib.sha1(n.encode()).digest()[:16],
    "sha256_32": lambda n: hashlib.sha256(n.encode()).digest(),
}

for hname, hfunc in hypotheses.items():
    for name in known_names[:3]:
        h = hfunc(name)
        b64 = base64.b64encode(h).decode()
        match = any(k == b64 for k in existing_keys)
        if match:
            print(f"  *** MATCH: {hname}({name}) = {b64}")
        else:
            # also try with utf-16le encoding
            h2 = hfunc(name.encode('utf-16-le') + b'\x00\x00') if True else None
            if h2:
                b642 = base64.b64encode(h2).decode()
                if any(k == b642 for k in existing_keys):
                    print(f"  *** MATCH (utf16): {hname}({name}) = {b642}")

# Also try: maybe the key uses the KIC "secret" from the binary
# Search krt.dll for known crypto constants (AES sbox, TEA delta, etc)
print("\n=== Crypto constants in krt.dll ===")
data = open(r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\krt.dll", 'rb').read()
consts = {
    "TEA delta": struct.pack('<I', 0x9E3779B9),
    "AES sbox start": bytes([0x63, 0x7c, 0x77, 0x7b]),
    "SHA256 K[0]": struct.pack('<I', 0x428A2F98),
    "SHA1 H[0]": struct.pack('>I', 0x67452301),
    "MD5 init": struct.pack('<I', 0x67452301),
    "SM4 sbox": bytes([0xd6, 0x90, 0xe9, 0xfe]),
    "CRC32": struct.pack('<I', 0xEDB88320),
}
for cname, cbytes in consts.items():
    pos = data.find(cbytes)
    if pos >= 0:
        print(f"  {cname}: FOUND @0x{pos:X}")
    else:
        print(f"  {cname}: not found")

# Try RC4 with common keys
print("\n=== Testing RC4/XOR ===")
def rc4(key, data):
    S = list(range(256))
    j = 0
    for i in range(256):
        j = (j + S[i] + key[i % len(key)]) % 256
        S[i], S[j] = S[j], S[i]
    i = j = 0
    out = bytearray()
    for byte in data:
        i = (i + 1) % 256
        j = (j + S[i]) % 256
        S[i], S[j] = S[j], S[i]
        out.append(byte ^ S[(S[i] + S[j]) % 256])
    return bytes(out)

# Try RC4 with the key being the switch name itself
name = known_names[0]  # type.scene_recommend
target_key = base64.b64decode(existing_keys[0])  # first existing key
result = rc4(name.encode(), b'\x00' * len(target_key))
print(f"  RC4(name, zeros) = {result[:16].hex()}")
print(f"  target          = {target_key[:16].hex()}")

# Try simple XOR
for xor_key in [b'kic', b'kingsoft', b'wps', b'krt']:
    result = bytes(b ^ xor_key[i % len(xor_key)] for i, b in enumerate(name.encode()))
    b64 = base64.b64encode(result[:32]).decode()
    print(f"  XOR({xor_key}, name) = {b64[:44]}")
