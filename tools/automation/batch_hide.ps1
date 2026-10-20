# Batch-hide: quarantine docer/prome/vip/AI/marketing addons
$office = 'C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6'
$quar   = 'C:\Users\1531\AppData\Local\Kingsoft\WPS Office\_quarantine\batch_hide'
New-Item -ItemType Directory -Force -Path $quar | Out-Null

$addons = @(
  # 稻壳 docer
  'kdocerbase','kdocercore','kdocercorelite','kdocerpage','kdocerresapply','kdocerresnetwork',
  'kdocerwpstemplate','kdocerjsapi20','kdocerjsapilite20',
  # prome 门户(稻壳AI模板标签页宿主)
  'kpromeaccountpanel','kpromeappmarket','kpromebrowser','kpromechuangkit','kpromeprocesson',
  'kpromeresume','kprometheusjsapi','kpromewebapp','kpromewebappruninfo','kpromeweblauncher','kpromeworkarea',
  # 会员/商城
  'kprivilegeresource','kprivilegerespack','kspostpay','kwebmemberrenewalpopup',
  'kappcenter','kappmarket','kappmgr','kapplist',
  # AI copilot
  'kcopilotentry','kcopilotentrylite','kcopilotjsapi','kcopilotsdk','kwppcopilot','kwppcopilotentry',
  'kwpscopilot','ktaskpanelcopilot','kwebwpscopilot','ketcopilot',
  # AI 功能
  'kwpsaigc','kwpsaiimagetool','kwpsaitablestyle','kwpsaitypeset','kwpsaitypesetassisant',
  'kwpsaiwordtool','kwpsaiwritingsuggest','kwpsaibasetypo','kwpsaifindreplace','kwpsblankgenerate','kwppaiquoteppt',
  # web AI
  'kwebaigenerateimage','kwebaiglossary','kwebaihistorysession','kwebaipdfinsight','kwebaireport',
  'kwebwpsainewfilepanel','kwebwppaioutline','kpubaigcbox',
  # pdf/et AI
  'kpdfaibookmark','kpdfaigcbox','kpdfaireference','kpdfaisearch','kpdfcopilot',
  'ketaitoolbox','ketaiformula','ketaidataanalysis','ketaiconditionalformat','ketaiselectcontent',
  # 营销/提示/皮肤
  'kcorppromotipsmgr','kskincenter','kwpscloudskin','kwebpromehelp','kwebwhatsnew','kwhatsnew',
  'kwebknovicetask','ktipsclientmanager','ktipsmanager',
  # 其他云入口
  'khoneycomb','kwebintegratedpanel','kwebdashboard','kwebdevicecenter','kcompanytabbutton'
)
$done = 0; $missing = @()
foreach ($a in $addons) {
    $src = Join-Path $office "addons\$a"
    if (Test-Path $src) {
        Move-Item $src (Join-Path $quar $a) -Force
        $done++
    } else { $missing += $a }
}
Write-Host "moved: $done"
if ($missing) { Write-Host ("not found: " + ($missing -join ',')) }
