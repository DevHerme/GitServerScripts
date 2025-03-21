# start-bugfix.ps1
. "$PSScriptRoot\common.ps1"

# Change to the project (Foundry) directory.
$configFile = Join-Path $PSScriptRoot "project-config.json"
Load-ProjectConfig -ConfigFilePath $configFile

if (-not (Test-Path $Script:ProjectPath)) {
    Write-Host "Project path '$($Script:ProjectPath)' not found. Exiting." -ForegroundColor Red
    exit 1
}
Set-Location $Script:ProjectPath

# Capture the original branch from the repository.
try {
    $global:originalBranch = (git rev-parse --abbrev-ref HEAD).Trim()
}
catch {
    Write-Host "Error: Not in a valid git repository at '$Script:ProjectPath'. Exiting." -ForegroundColor Red
    exit 1
}

Handle-UncommittedChanges
Switch-To-Branch $Script:StableBranch

$versionFile = Join-Path $Script:ProjectPath "version.txt"
if (Test-Path $versionFile) {
    $currentVersion = (Get-Content $versionFile -Raw).Trim()
} else {
    $currentVersion = "v0.0.0"
}
Write-Host "Current version: $currentVersion"

$BugfixName = Read-Host "Enter the new bugfix name (or type 'exit' to cancel)"
Check-ForExit $BugfixName
if ([string]::IsNullOrWhiteSpace($BugfixName)) {
    Write-Host "No bugfix name provided. Exiting without changes." -ForegroundColor Red
    exit 1
}
$bugfixNameSanitized = ($BugfixName.Trim() -replace '[^a-zA-Z0-9\-_\.]', '-')
$newBranch = "$currentVersion/bugfix/$bugfixNameSanitized"

Create-And-Push-Branch $newBranch

# Return explicitly to the local-server directory.
Set-Location $global:localServerDir
Write-Host "Returned to local-server directory: $global:localServerDir"
