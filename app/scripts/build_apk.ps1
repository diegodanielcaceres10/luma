# Compila el APK, lo renombra con nombre + versión + timestamp y lo deja
# en app/dist/ (fuera de git) junto con un alias "latest" fijo.
#
# Uso:
#   .\scripts\build_apk.ps1                    # release (default)
#   .\scripts\build_apk.ps1 -Mode debug
#   .\scripts\build_apk.ps1 -Install            # además instala en el dispositivo conectado (adb)
#
# Correr desde cualquier lado; el script se ubica solo en app/.

param(
    [ValidateSet("release", "debug")]
    [string]$Mode = "release",
    [switch]$Install
)

$ErrorActionPreference = "Stop"

# app/scripts/build_apk.ps1 -> app/
$AppDir = Split-Path -Parent $PSScriptRoot
Set-Location $AppDir

$AppName = "luma"

$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -notmatch 'version:\s*([\d\.]+)\+(\d+)') {
    throw "No pude leer 'version' de pubspec.yaml"
}
$VersionName = $Matches[1]
$BuildNumber = $Matches[2]

Write-Host "Compilando APK ($Mode)..." -ForegroundColor Cyan
flutter build apk "--$Mode"
if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk falló (exit code $LASTEXITCODE)"
}

$SrcApk = "build\app\outputs\flutter-apk\app-$Mode.apk"
if (-not (Test-Path $SrcApk)) {
    throw "No encontré el APK generado en $SrcApk"
}

$DistDir = "dist"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$DestApk = "$DistDir\$AppName-v$VersionName+$BuildNumber-$Mode-$Timestamp.apk"
$LatestApk = "$DistDir\$AppName-latest-$Mode.apk"

Move-Item -Force $SrcApk $DestApk
Copy-Item -Force $DestApk $LatestApk

Write-Host "APK listo:" -ForegroundColor Green
Write-Host "  $DestApk"
Write-Host "  $LatestApk  (alias fijo, para instalar sin acordarte el nombre exacto)"

if ($Install) {
    Write-Host "Instalando en el dispositivo conectado..." -ForegroundColor Cyan
    adb install -r $DestApk
}
