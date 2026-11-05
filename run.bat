@echo off
echo ========================================================
echo   WRONG WAY - Tezkor O'rnatish va Ishga Tushirish
echo ========================================================

set GODOT="D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
set ADB="C:\Users\asror\AppData\Local\Android\Sdk\platform-tools\adb.exe"

echo [1/3] APK eksport qilinmoqda...
%GODOT% --headless --export-debug "Android" build/wrong-way.apk
if %ERRORLEVEL% NEQ 0 (
    echo [XATOLIK] Eksport jarayonida xatolik yuz berdi!
    pause
    exit /b %ERRORLEVEL%
)

echo [2/3] Telefonga o'rnatilmoqda...
%ADB% install -r build/wrong-way.apk
if %ERRORLEVEL% NEQ 0 (
    echo [XATOLIK] Telefonga o'rnatib bo'lmadi! Telefon ulanganini tekshiring.
    pause
    exit /b %ERRORLEVEL%
)

echo [3/3] Telefonda ishga tushirilmoqda...
%ADB% shell monkey -p com.asror.wrongway -c android.intent.category.LAUNCHER 1

echo ========================================================
echo   O'yin telefonda muvaffaqiyatli ishga tushdi!
echo ========================================================
