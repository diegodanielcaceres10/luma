# Runs the app in the browser with the variables from app/.env.
#
# Usage:
#   .\scripts\run.ps1                          # Chrome on port 5005
#   .\scripts\run.ps1 -Port 5010               # another web port
#   .\scripts\run.ps1 -Device windows          # another device (the port is ignored)
#
# Can be run from anywhere; the script locates app/ by itself. Press q in the
# terminal to quit.

param(
    [string]$Device = "chrome",
    [int]$Port = 5005
)

. "$PSScriptRoot\_common.ps1"

Start-Task "Running the app on $Device" {
    Enter-AppDir
    Assert-EnvFile

    $runArgs = @("run", "-d", $Device)
    # Only web devices take a port.
    if (@("chrome", "edge", "web-server") -contains $Device) {
        $runArgs += "--web-port=$Port"
    }
    $runArgs += "--dart-define-from-file=$script:EnvFileName"

    Invoke-Flutter @runArgs
}
