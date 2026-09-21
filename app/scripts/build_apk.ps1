# Compila el APK en modo debug (release lo genera GitHub) y lo deja en
# app/dist/ (fuera de git) con nombre luma-app-debug-<timestamp>.apk.
#
# Uso:
#   .\scripts\build_apk.ps1              # compila e instala en dist/
#   .\scripts\build_apk.ps1 -Install     # además instala en el dispositivo conectado (adb)
#
# Correr desde cualquier lado; el script se ubica solo en app/.

param(
    [switch]$Install
)

$ErrorActionPreference = "Stop"

# app/scripts/build_apk.ps1 -> app/
$AppDir = Split-Path -Parent $PSScriptRoot
Set-Location $AppDir

# Las variables (Supabase, Google) se compilan dentro del APK desde app\.env;
# ya no viajan como asset. Ver README.
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
