# Runs the Flutter tests. Extra arguments go to `flutter test`.
#
# Usage:
#   .\scripts\test.ps1                              # whole suite
#   .\scripts\test.ps1 test\core\ai                 # one folder or file
#   .\scripts\test.ps1 --name "keeps each stage"    # tests matching a name
#
# Can be run from anywhere; the script locates app/ by itself. Paths are
# relative to app/.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

. "$PSScriptRoot\_common.ps1"

Start-Task "Running tests" {
    Enter-AppDir
    Invoke-Flutter test @FlutterArgs
}
