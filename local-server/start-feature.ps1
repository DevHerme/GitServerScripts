# start-feature.ps1
. "$PSScriptRoot\common.ps1"

# Load configuration.
$configFile = Join-Path $PSScriptRoot "project-config.json"
Load-ProjectConfig -ConfigFilePath $configFile

# Verify that the project directory (Foundry) exists.
if (-not (Test-Path $Script:ProjectPath)) {
    Write-Host "Project path '$($Script:ProjectPath)' not found. Exiting." -ForegroundColor Red
    exit 1
}

# Change to the Foundry directory.
Set-Location $Script:ProjectPath

# Now capture the original branch (after changing to the repository directory).
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

$FeatureName = Read-Host "Enter the new feature name (or type 'exit' to cancel)"
Check-ForExit $FeatureName
if ([string]::IsNullOrWhiteSpace($FeatureName)) {
    Write-Host "No feature name provided. Exiting without changes." -ForegroundColor Red
    exit 1
}
$featureNameSanitized = ($FeatureName.Trim() -replace '[^a-zA-Z0-9\-_\.]', '-')
$newBranch = "$currentVersion/feature/$featureNameSanitized"

Create-And-Push-Branch $newBranch

# Explicitly return to the local-server directory.
Set-Location $global:localServerDir
Write-Host "Returned to local-server directory: $global:localServerDir"
