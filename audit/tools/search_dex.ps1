Add-Type -AssemblyName System.IO.Compression.FileSystem
$apkPath = "build/wrong-way.apk"
$zip = [System.IO.Compression.ZipFile]::OpenRead($apkPath)

$found = @()
foreach ($entry in $zip.Entries) {
    if ($entry.Name -match "\.dex$") {
        $stream = $entry.Open()
        $reader = New-Object System.IO.BinaryReader($stream)
        $bytes = $reader.ReadBytes($entry.Length)
        $stream.Close()
        $str = [System.Text.Encoding]::ASCII.GetString($bytes)
        
        $hasPoing = $str.Contains("PoingGodotAdMob")
        $hasGmsAds = $str.Contains("com/google/android/gms/ads")
        $hasGodotAdMob = $str.Contains("GodotAdMob")
        
        if ($hasPoing -or $hasGmsAds -or $hasGodotAdMob) {
            $found += [PSCustomObject]@{
                Dex = $entry.Name
                HasPoing = $hasPoing
                HasGmsAds = $hasGmsAds
                HasGodotAdMob = $hasGodotAdMob
            }
        }
    }
}
$zip.Dispose()

Write-Host "Dex files containing AdMob signatures:"
$found | Format-Table -AutoSize

