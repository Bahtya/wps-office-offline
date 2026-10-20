# Enumerate login/guest/visitor-related exports in core modules
import re, pefile

ROOT = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6"
MODS = ["kshell.dll", "kso.dll", "ksolite.dll", "ksal.dll", "kwpsmain.dll", "ksocial.dll", "kaccount.dll", "klogin.dll"]
PAT = re.compile(r'(IsLogin|LoginState|LoginStatus|LoginMode|ForceLogin|NeedLogin|IsLogged|LoggedIn|Visitor|Guest|IsGuest|GuestMode|VisitorMode|AccountState|LoginInfo|GetLoginUser|IsUserLogin|UserLogin|LoginValid|CanEdit)', re.I)

for m in MODS:
    p = f"{ROOT}\\{m}"
    try:
        pe = pefile.PE(p, fast_load=True)
        pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
        exp = getattr(pe, 'DIRECTORY_ENTRY_EXPORT', None)
        if not exp:
            print(f"== {m}: no exports")
            continue
        hits = [(s.address, s.name.decode('utf-8', 'replace')) for s in exp.symbols
                if s.name and PAT.search(s.name.decode('utf-8', 'replace'))]
        print(f"== {m}: {len(exp.symbols)} exports, {len(hits)} matched")
        for rva, n in sorted(hits):
            print(f"   RVA 0x{rva:08X}  {n}")
    except FileNotFoundError:
        pass
    except Exception as e:
        print(f"== {m}: error {e}")
