# switch-branch.ps1
. "$PSScriptRoot\common.ps1"

# 1. Load configuration and change to the Foundry directory.
$configFile = Join-Path $PSScriptRoot "project-config.json"
Load-ProjectConfig -ConfigFilePath $configFile

if (-not (Test-Path $Script:ProjectPath)) {
    Write-Host "Project path '$($Script:ProjectPath)' not found. Exiting." -ForegroundColor Red
    exit 1
}
Set-Location $Script:ProjectPath

Handle-UncommittedChanges

# 2. Read current version from version.txt.
$versionFile = Join-Path $Script:ProjectPath "version.txt"
if (-not (Test-Path $versionFile)) {
    Write-Host "No version.txt found. Defaulting to 'v0.0.0'." -ForegroundColor Yellow
    $currentVersion = "v0.0.0"
} else {
    $currentVersion = (Get-Content $versionFile -Raw).Trim()
}
$escapedVersion = [Regex]::Escape($currentVersion)
$versionRegex = "^$escapedVersion/(feature|bugfix|hotfix)/"

# 3. Retrieve remote branch names using git ls-remote.
Write-Host "Fetching remote branch names..."
$lsRemoteOutput = git ls-remote --heads origin | Out-String
$remoteBranches = @()
foreach ($line in $lsRemoteOutput -split "`n") {
    $line = $line.Trim()
    if ($line -match "refs/heads/(.+)$") {
        $remoteBranches += $matches[1]
    }
}

# 4. Filter branches: only include stable branch or branches matching the version regex.
$filteredList = New-Object System.Collections.Generic.List[PSCustomObject]
foreach ($branchName in $remoteBranches) {
    if ($branchName -eq $Script:StableBranch -or $branchName -match $versionRegex) {
        $filteredList.Add([pscustomobject]@{
            Display = $branchName
        })
    }
}

if ($filteredList.Count -eq 0) {
    Write-Host "No matching remote branches found for version '$currentVersion' or stable branch '$($Script:StableBranch)'. Exiting." -ForegroundColor Red
    exit 1
}

# 5. Recapture current branch before listing, so we know which one is current.
try {
    $global:originalBranch = (git rev-parse --abbrev-ref HEAD).Trim()
} catch {
    Write-Host "Error recapturing current branch. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "`nAvailable remote branches (version '$currentVersion' + stable):" -ForegroundColor Cyan
for ($i = 0; $i -lt $filteredList.Count; $i++) {
    $displayName = $filteredList[$i].Display
    if ($displayName -eq $global:originalBranch) {
        $displayName += " (current)"
    }
    Write-Host "[$i] $displayName"
}

# 6. Prompt for selection.
$choice = Read-Host "Enter the number of the branch you want to switch to (or type 'exit' to cancel)"
Check-ForExit $choice
if ($choice -notmatch '^\d+$' -or [int]$choice -ge $filteredList.Count) {
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    exit 1
}

$selected = $filteredList[[int]$choice]
$targetBranch = $selected.Display

Write-Host "Switching to branch '$targetBranch'..."

# 7. Attempt checkout.
$checkoutResult = & git checkout $targetBranch 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "git checkout $targetBranch failed. Attempting to create a local tracking branch from origin/$targetBranch..." -ForegroundColor Yellow
    & git checkout -b $targetBranch "origin/$targetBranch" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to create local tracking branch for '$targetBranch'. Exiting." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Switched to branch '$targetBranch'."

# 8. Recapture the new branch.
try {
    $global:originalBranch = (git rev-parse --abbrev-ref HEAD).Trim()
} catch {
    Write-Host "Could not recapture new branch. Exiting." -ForegroundColor Red
    exit 1
}
Write-Host "Recaptured new original branch: $global:originalBranch"

# 9. Return to the local-server directory.
Set-Location $global:localServerDir
Write-Host "Returned to local-server directory: $global:localServerDir"

# Explicitly exit to end the script.
exit 0
