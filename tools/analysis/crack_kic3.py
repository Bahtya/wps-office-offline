# Clean rewrite: test crypto hypotheses properly
import hashlib, base64, struct

existing_keys = [
    "6yNvOS114l8rSL+kOuqwC0F1uYEKqK0txnQophtU3m4=",
    "jTQDZ60PH0TgGVc5XPR/PU7FlhQ8sfv+Ir0usxuF3ZU=",
    "qA32MuVupIR0D+2e/hYicA==",
    "qssOqcEcuBksgfkgNmgDpW3dpPs4ssTllPQRRIC7smA=",
    "acDkBNIdhqvnq4dBKpXAHPoIu0Zp53bEPEBHr+J7KWE=",
    "6GjQUxiYYdH8NxOVJUdpOAjJeIHv/0n3dzAUyF0tGYo=",
    "VSXFEuhyZ+7MHjXCpG0+tBIZpYyWuOAgJbjlxkCYroM=",
    "uWEXwvpGEA0DSF5Ae3PdqUF1uYEKqK0txnQophtU3m4=",
    "kaQm19O36bskO7uwj2PeAJN5951KEClWCpFJR5RHyJs=",
    "PMMpgkp8ls/4qfEiWKL9gvL4eyv2r9wg2ea0HbDpK48=",
    "pyoJeTexMJjB7c+B5ylpHt+wVeomk+s2MWuw1Y4FoIg=",
]
known_names = [
    "type.scene_recommend", "type.template", "type.online_template",
    "type.vas_shellext", "type.cloud_shellext", "type.compress_shellext",
    "type.desktop_shellext", "type.recyclerecovery_shellext",
    "type.freediskspace_shellext", "type.wpsai_shellext",
    "type.edit_shellext", "type.vas_shellnewext",
]

def test_hash(name_bytes, hash_func, label):
    h = hash_func(name_bytes)
    b64 = base64.b64encode(h).decode()
    for k in existing_keys:
        if k == b64:
            print(f"  *** MATCH: {label} -> {b64[:44]}")
            return True
    return False

print("=== Hash hypotheses ===")
found = False
for name in known_names:
    for enc_label, name_bytes in [("utf8", name.encode()), ("utf16le", name.encode('utf-16-le') + b'\x00\x00')]:
        if test_hash(name_bytes, lambda b: hashlib.md5(b).digest(), f"md5/{enc_label}({name})"): found = True
        if test_hash(name_bytes, lambda b: hashlib.sha256(b).digest(), f"sha256/{enc_label}({name})"): found = True
        if test_hash(name_bytes, lambda b: hashlib.sha1(b).digest()[:16] + b'\x00'*16, f"sha1pad/{enc_label}({name})"): found = True
        if test_hash(name_bytes, lambda b: hashlib.sha1(b).digest(), f"sha1/{enc_label}({name})"): found = True
if not found:
    print("  No simple hash match found.")

# Check crypto constants in krt.dll
print("\n=== Crypto constants in krt.dll ===")
data = open(r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\krt.dll", 'rb').read()
for cname, cbytes in [
    ("TEA delta", struct.pack('<I', 0x9E3779B9)),
    ("AES sbox", bytes([0x63, 0x7c, 0x77, 0x7b])),
    ("SHA256 K", struct.pack('<I', 0x428A2F98)),
    ("SHA256 K big-endian", struct.pack('>I', 0x428A2F98)),
    ("SHA1 H", struct.pack('>I', 0x67452301)),
    ("MD5 init", struct.pack('<I', 0x67452301)),
    ("SM4 sbox", bytes([0xd6, 0x90, 0xe9, 0xfe])),
    ("CRC32", struct.pack('<I', 0xEDB88320)),
    ("CRC32 rev", struct.pack('<I', 0x04C11DB7)),
]:
    pos = data.find(cbytes)
    print(f"  {cname}: {'FOUND @0x%X' % pos if pos >= 0 else 'not found'}")

# Key observation: key[0] and key[7] end with SAME bytes:
# "6yNvOS114l8rSL+kOuqwC0F1uYEKqK0txnQophtU3m4=" vs
# "uWEXwvpGEA0DSF5Ae3PdqUF1uYEKqK0txnQophtU3m4="
# The last 20 base64 chars (15 bytes) are IDENTICAL!
# This means the last 15 bytes are the same for different switch names.
# This suggests a BLOCK CIPHER where the last block encrypts the same padding.
print("\n=== Key suffix analysis ===")
k1 = base64.b64decode(existing_keys[0])
k7 = base64.b64decode(existing_keys[7])
print(f"key1 ({len(k1)}B): ...{k1[-16:].hex()}")
print(f"key7 ({len(k7)}B): ...{k7[-16:].hex()}")
same = sum(1 for a, b in zip(k1, k7) if a == b)
print(f"identical trailing bytes: {same}/{min(len(k1),len(k7))}")
print(f"k1[12:] == k7[12:]: {k1[12:] == k7[12:]}")
# ECB mode with 16-byte blocks: if plaintext differs only in first block,
# second block would be identical only if it encrypts the same content.
# This is consistent with AES-ECB where the tail is zero-padding.

# Also check: key3 is only 16 bytes while others are 32
k3 = base64.b64decode(existing_keys[2])
print(f"\nkey3 len: {len(k3)} (short key = short name?)")
