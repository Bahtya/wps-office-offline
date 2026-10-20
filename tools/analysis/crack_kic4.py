# Key finding: k1[12:] != k7[12:] but they share 17/32 identical bytes.
# Let me look more carefully at which bytes differ.
# Also: AES sbox + SHA256 + MD5 all found in krt.dll = real crypto present.
#
# The trailing bytes being MOSTLY identical suggests these are encrypted names
# where the plaintext names share a common suffix (like "_shellext").
#
# Let me analyze byte-by-byte:

import base64

keys_b64 = [
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

keys = [base64.b64decode(k) for k in keys_b64]
print("=== Byte-by-byte comparison (key[0] vs all others) ===")
k0 = keys[0]
for i, k in enumerate(keys):
    if i == 0: continue
    same_pos = [j for j in range(min(len(k0), len(k))) if k0[j] == k[j]]
    diff_pos = [j for j in range(min(len(k0), len(k))) if k0[j] != k[j]]
    print(f"  k[{i}] vs k[0]: same at {same_pos}, diff at {diff_pos}")

# Check: are the last N bytes always the same across all 32-byte keys?
print("\n=== Trailing bytes analysis ===")
k32 = [k for k in keys if len(k) == 32]
for tail_len in [4, 8, 12, 15, 16, 20]:
    all_same = all(k[-tail_len:] == k32[0][-tail_len:] for k in k32)
    print(f"  last {tail_len} bytes identical across all 32B keys: {all_same}")

# The fact that SOME trailing bytes match means the plaintext has a common suffix
# and the encryption is a STREAM cipher or CTR mode (position-dependent).
# In CTR mode: ciphertext[i] = plaintext[i] XOR keystream[i]
# If plaintexts share suffix "_shellext", the ciphertexts share it too (same positions).
# This means we can DERIVE the keystream if we know the plaintext!

print("\n=== CTR/stream cipher hypothesis test ===")
# If k0 encrypts a name of length ~32 that ends with "_shellext":
# and another key encrypts a different name also ending with "_shellext",
# XOR of the two ciphertexts at those positions = XOR of the two plaintexts.
# Since both end with "_shellext", the XOR at the tail should be 0x00 for those positions.
k0h = keys[0].hex()
k7h = keys[7].hex()
xor = bytes(a ^ b for a, b in zip(keys[0], keys[7]))
print(f"  k0 XOR k7 = {xor.hex()}")
print(f"  zero bytes in XOR (same plaintext positions): {[i for i,b in enumerate(xor) if b==0]}")

# Try all pairs
print("\n=== All pair XORs zero-tail analysis ===")
for i in range(len(k32)):
    for j in range(i+1, len(k32)):
        xor = bytes(a ^ b for a, b in zip(k32[i], k32[j]))
        zeros = [pos for pos, b in enumerate(xor) if b == 0]
        if len(zeros) >= 8:
            print(f"  k{i}^k{j}: zeros at {zeros}")
