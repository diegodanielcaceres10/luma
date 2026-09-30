# Builds a debug APK (release is built by GitHub) into app/dist/ (git-ignored)
# as luma-app-debug-<timestamp>.apk.
#
# Usage:
#   .\scripts\build_apk.ps1            # build into dist/
#   .\scripts\build_apk.ps1 -Install   # also install on the connected device (adb)
#
# Can be run from anywhere; the script locates app/ by itself.

param(
    [switch]$Install
)

$ErrorActionPreference = "Stop"

$AppDir = Split-Path -Parent $PSScriptRoot
Set-Location $AppDir

$EnvFile = ".env"
if (-not (Test-Path $EnvFile)) {
    throw "No encontré app\$EnvFile (copiá .env.example y completalo)"
}

Write-Host "Compilando APK (debug)..." -ForegroundColor Cyan
flutter build apk --debug --android-skip-build-dependency-validation --dart-define-from-file=$EnvFile
if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk falló (exit code $LASTEXITCODE)"
}

$SrcApk = "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $SrcApk)) {
    throw "No encontré el APK generado en $SrcApk"
}

$DistDir = "dist"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$DestApk = "$DistDir\luma-app-debug-$Timestamp.apk"

Move-Item -Force $SrcApk $DestApk

Write-Host "APK listo: $DestApk" -ForegroundColor Green

if ($Install) {
    Write-Host "Instalando en el dispositivo conectado..." -ForegroundColor Cyan
    adb install -r $DestApk
}
