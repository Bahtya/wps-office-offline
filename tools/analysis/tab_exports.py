# Find tab-injection exports in ksolite.dll and kprometheus.dll
import pefile, re

ROOT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6"
PAT = re.compile(r'(VipSpecialTab|DocerFake|AIGCProxy|FakeTab|WorkSpace|MemberTab|PromotionTab|SphereTab|RbTab.*Vip|addTab|insertTab|AppendTab|registerTab)', re.I)

for mod in ["kprometheus.dll", "ksolite.dll"]:
    p = f"{ROOT}\\{mod}"
    pe = pefile.PE(p, fast_load=True)
    pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
    exp = getattr(pe, 'DIRECTORY_ENTRY_EXPORT', None)
    if not exp:
        print(f"== {mod}: no exports"); continue
    hits = [(s.address, s.name.decode('utf-8','replace')) for s in exp.symbols
            if s.name and PAT.search(s.name.decode('utf-8','replace'))]
    print(f"== {mod}: {len(exp.symbols)} exports, {len(hits)} matched")
    for rva, n in sorted(hits)[:60]:
        print(f"   RVA 0x{rva:08X}  {n}")
