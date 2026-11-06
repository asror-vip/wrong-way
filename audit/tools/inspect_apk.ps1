Add-Type -AssemblyName System.IO.Compression.FileSystem
$apkPath = "build/wrong-way.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "APK not found: $apkPath"
    exit 1
}
$zip = [System.IO.Compression.ZipFile]::OpenRead($apkPath)
$entries = $zip.Entries

Write-Host "Total entries in APK:" $entries.Count

$admobEntries = $entries | Where-Object { $_.FullName -match "admob|poing|google/android/gms/ads" }
Write-Host "AdMob-related entries in APK:" $admobEntries.Count
$admobEntries | Select-Object FullName

$dexEntries = $entries | Where-Object { $_.FullName -match "\.dex$" }
Write-Host "Dex files:" $dexEntries.Count
$dexEntries | Select-Object FullName, Length

$libEntries = $entries | Where-Object { $_.FullName -match "^lib/" }
Write-Host "Native .so libraries:" $libEntries.Count
$libEntries | Select-Object FullName

$zip.Dispose()

