# Find KIC switch getter exports in ksolite/kprometheus
import pefile, re

ROOT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6"
PAT = re.compile(r'(kic.{0,20}switch|switch.{0,20}(value|state|get|open|enable)|GetKicValue|KicGet|featureswitch)', re.I)

for mod in ["ksolite.dll", "kprometheus.dll"]:
    p = f"{ROOT}\\{mod}"
    pe = pefile.PE(p, fast_load=True)
    pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
    exp = getattr(pe, 'DIRECTORY_ENTRY_EXPORT', None)
    if not exp:
        print(f"== {mod}: no exports"); continue
    hits = [(s.address, s.name.decode('utf-8','replace')) for s in exp.symbols
            if s.name and PAT.search(s.name.decode('utf-8','replace'))]
    # also broad: anything with 'Kic' token
    hits2 = [(s.address, s.name.decode('utf-8','replace')) for s in exp.symbols
             if s.name and re.search(r'\bKic\b|Kic[A-Z]', s.name.decode('utf-8','replace'))]
    print(f"== {mod}: pattern={len(hits)} kic-token={len(hits2)}")
    for rva, n in sorted(set(hits + hits2))[:40]:
        print(f"   RVA 0x{rva:08X}  {n}")
