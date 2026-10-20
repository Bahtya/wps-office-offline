# Dump kshell.dll exports filtered by login/account/session keywords
import re, pefile, sys

DLL = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\kshell.dll"
pat = re.compile(sys.argv[1] if len(sys.argv) > 1 else r'(login|logon|signin|sign_in|guest|account|ksession|userstate|vip|member|auth)', re.I)

pe = pefile.PE(DLL, fast_load=True)
pe.parse_data_directories(
    directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])

exp = pe.DIRECTORY_ENTRY_EXPORT
base = pe.OPTIONAL_HEADER.ImageBase
hits = []
for sym in exp.symbols:
    if sym.name is None:
        continue
    n = sym.name.decode('utf-8', 'replace')
    if pat.search(n):
        hits.append((sym.address, n))

print(f"total exports: {len(exp.symbols)}, matched: {len(hits)}")
for rva, n in sorted(hits):
    print(f"RVA 0x{rva:08X}  {n}")
