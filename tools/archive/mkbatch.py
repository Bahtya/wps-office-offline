import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
OFFICE = r"C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158"

def entry_for(path):
    return re.sub(r'[:\\]+', '_', path)

root_files = ['wpscloudsvr.exe','wpscloudlaunch.exe','kwpswnsserver.exe','promecefpluginhost.exe',
 'wpslingxi.exe','photolaunch.exe','kcrashdumper.exe','kcrashdumper64.exe','transerr.exe',
 'qingnse.dll','qingnse64.dll','kqingaccountsdk.dll','pintaskbar.exe','kwinappinstaller.exe']
batchA = [entry_for(os.path.join(OFFICE, 'office6', f)) for f in root_files]
batchA.append(entry_for(os.path.join(OFFICE, 'wtoolex')))

ref = ['kdatamarket','kdiagnostictools','kwpsaigc','kappcenter','kappmgr','kcloudfiledialog','kcopilotentry',
 'kcopilotentrylite','kcopilotsdk','kcoworkdockpanel','ketaidataanalysis','ketcopilot','khelp','klingxidockpanel',
 'kpubaigcbox','kwebaireport','kwebdashboard','kwpslingxi','officespace','photo','kaiwpp','kaiwps','kappconnectivity',
 'kclouddocs','kdocercore','kdocercorelite','kdocerpage','khyperion','klayoutopt','kmessagecentersdk',
 'kmessagecentersrv','knewdoc','knewdocs','kpromeaccountpanel','kpromeappmarket','kpromebrowser','kpromechuangkit',
 'kpromeprocesson','kpromeresume','kpromewebapp','kpromeworkarea','kqingdlg','krecentfile','kskincenter',
 'ksmartnetwork','kstartpage','ktastenewpage','kusercenter','kwebwhatsnew','kwhatsnew','kwpscloudmodule',
 'kwpscloudskin','kwpscowork','kwpsnote','kwpsupdateui','messagepush','yunbox','kaicloudsdk','kdcsdk',
 'kdocerjsapi20','kfeedback','kfileradarguide','knetwork','kwebonlinetaskpane','kwppcopilot','multiclipboard',
 'photoeditlite','photopreviewerlite','kassosettingguide','kcloudadapter','kcorppromotipsmgr','kdatamigration',
 'kentcloudconfig','kextensionmgr','khoneycomb','knimbusconfig','konlinefileconfig','kplugindistributer',
 'kpluginmanager','ktaskpanelcopilot','ktipsclientmanager','ktipsmanager','kwebdocscontrol','kwebeditioninfo',
 'kwebwpscopilot','karticlewebcloudsummary','kpdfaibookmark','kpdfaigcbox','kpdfaireference','kpdfaisearch',
 'kpdfcopilot','ksphotokit','kspostpay','kwebaipdfinsight','kwebaigenerateimage','kwebwpsdoccomposing',
 'kwpsaibasetypo','kwpsaifindreplace','kwpsaitablestyle','kwpsaitypeset','kwpsaitypesetassisant','kwpsaiwordtool',
 'kwpsaiwritingsuggest','kwpsblankgenerate','kwpscopilot','kwpsmathor','kwppmathor']
seen = set(); batchB = []
for n in ref:
    if n in seen: continue
    seen.add(n)
    p = os.path.join(OFFICE, 'office6', 'addons', n)
    if os.path.exists(p): batchB.append(entry_for(p))
here = os.path.dirname(os.path.abspath(__file__))
open(os.path.join(here, 'batchA.txt'), 'w').write('\n'.join(batchA))
open(os.path.join(here, 'batchB.txt'), 'w').write('\n'.join(batchB))
print('batchA(root+wtoolex):', len(batchA), ' batchB(core-referenced addons):', len(batchB))
