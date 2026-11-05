Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   WRONG WAY - Tezkor O'rnatish va Ishga Tushirish" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

$GODOT = "D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$ADB = "C:\Users\asror\AppData\Local\Android\Sdk\platform-tools\adb.exe"

Write-Host "`n[1/3] APK eksport qilinmoqda..." -ForegroundColor White
& $GODOT --headless --export-debug "Android" build/wrong-way.apk
if ($LASTEXITCODE -ne 0) {
    Write-Host "[XATOLIK] Eksport muvaffaqiyatsiz bo'ldi!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`n[2/3] Telefonga o'rnatilmoqda..." -ForegroundColor White
& $ADB install -r build/wrong-way.apk
if ($LASTEXITCODE -ne 0) {
    Write-Host "[XATOLIK] Telefonga o'rnatib bo'lmadi! ADB tekshiring." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`n[3/3] Telefonda ishga tushirilmoqda..." -ForegroundColor Green
& $ADB shell monkey -p com.asror.wrongway -c android.intent.category.LAUNCHER 1

Write-Host "`nO'yin telefoningizda muvaffaqiyatli ishga tushdi!" -ForegroundColor Green
