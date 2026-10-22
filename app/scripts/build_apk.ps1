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

. "$PSScriptRoot\_common.ps1"

Start-Task "Building debug APK" {
    Enter-AppDir
    Assert-EnvFile

    Invoke-Flutter build apk --debug --android-skip-build-dependency-validation "--dart-define-from-file=$script:EnvFileName"

    $srcApk = "build/app/outputs/flutter-apk/app-debug.apk"
    if (-not (Test-Path $srcApk)) {
        throw "Generated APK not found at $srcApk"
    }

    $distDir = "dist"
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $destApk = Join-Path $distDir "luma-app-debug-$timestamp.apk"
    Move-Item -Force $srcApk $destApk
    Write-Ok "APK ready: $destApk"

    if ($Install) {
        Write-Step "Installing on the connected device"
        if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
            throw "adb was not found in PATH. Install the Android platform tools to use -Install."
        }
        Write-Info "Command: adb install -r $destApk"
        & adb install -r $destApk
        if ($LASTEXITCODE -ne 0) {
            throw "adb install failed (exit code $LASTEXITCODE)"
        }
        Write-Ok "APK installed"
    }
}
