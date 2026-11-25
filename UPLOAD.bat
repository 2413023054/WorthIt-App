@echo off
echo ===================================================
echo   MENGUNGGAH APLIKASI WORTHIT KE GITHUB ACTIONS
echo ===================================================
echo.

git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git belum terpasang di komputer ini!
    echo Silakan unduh dan pasang Git dari: https://git-scm.com/download/win
    echo Setelah selesai pasang Git, klik dua kali file UPLOAD.bat ini lagi.
    pause
    exit /b
)

echo [1/5] Inisialisasi Git...
git init

echo [2/5] Menambahkan seluruh file proyek dan .github...
git add .

echo [3/5] Membuat commit...
git commit -m "feat: build apk worthit android"

echo [4/5] Mengatur branch main dan remote GitHub...
git branch -M main
git remote remove origin >nul 2>&1
git remote add origin https://github.com/2413023054/WorthIt-2.git

echo [5/5] Mengunggah ke GitHub...
git push -u origin main

echo.
echo ===================================================
echo   BERHASIL! BUKA TAB ACTIONS DI GITHUB ANDA:
echo   https://github.com/2413023054/WorthIt-2/actions
echo   Tunggu 3-4 menit untuk download file APK-nya!
echo ===================================================
pause
