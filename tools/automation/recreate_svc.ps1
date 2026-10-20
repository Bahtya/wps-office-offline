# Elevated service creation via New-Service — file logging only
$log = 'C:\Users\1531\Documents\project\re-wps\tools\svc_log2.txt'
function L($m) { Add-Content -Path $log -Value $m }
Set-Content -Path $log -Value "=== run $(Get-Date) ==="

$exe = 'C:\Users\1531\AppData\Local\Kingsoft\WPS Office\12.1.0.29158\office6\wpscloudsvr.exe'
L ("exe exists: " + (Test-Path $exe))

if (Get-Service wpscloudsvr -ErrorAction SilentlyContinue) {
    L 'service already exists'
} else {
    try {
        New-Service -Name wpscloudsvr -DisplayName 'WPS Office Cloud Service' `
            -Description 'WPS Office Cloud Service' `
            -BinaryPathName ('"' + $exe + '" LocalService') `
            -StartupType Manual -ErrorAction Stop | Out-Null
        L 'New-Service ok'
    } catch {
        L "New-Service failed: $_"
    }
}

try {
    Start-Service wpscloudsvr -ErrorAction Stop
    L 'Start-Service ok'
} catch {
    L "Start-Service failed: $_"
}

Start-Sleep 2
$s = Get-Service wpscloudsvr -ErrorAction SilentlyContinue
if ($s) { L ("status: " + $s.Status) }
$proc = Get-Process wpscloudsvr -ErrorAction SilentlyContinue
if ($proc) { L ("proc pid=" + $proc.Id) } else { L 'proc none' }
L "=== done ==="
