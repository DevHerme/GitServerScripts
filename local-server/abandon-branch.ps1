# abandon-branch.ps1
. "$PSScriptRoot\common.ps1"

$configFile = Join-Path $PSScriptRoot "project-config.json"
Load-ProjectConfig -ConfigFilePath $configFile

if (-not (Test-Path $Script:ProjectPath)) {
    Write-Host "Project path '$($Script:ProjectPath)' not found. Exiting." -ForegroundColor Red
    Set-Location $global:localServerDir
    exit 1
}
Set-Location $Script:ProjectPath

Handle-UncommittedChanges

# Capture the currently active branch.
$currentActive = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Current active branch: $currentActive" -ForegroundColor Cyan

Write-Host "Fetching list of local branches that are not marked as deprecated..."
$branchesRaw = git branch --list | Out-String
$allBranches = $branchesRaw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

$validBranches = @()
foreach ($b in $allBranches) {
    $clean = $b -replace '^\*', '' -replace '^\s+', ''
    # Do not allow abandoning the stable branch.
    if ($clean -eq $Script:StableBranch) { continue }
    # Skip branches already marked as deprecated.
    if ($clean -match '^deprecated/') { continue }
    $validBranches += $clean
}

if ($validBranches.Count -eq 0) {
    Write-Host "No valid branches to abandon. Exiting." -ForegroundColor Red
    Set-Location $global:localServerDir
    exit 1
}

Write-Host "`nAvailable branches to abandon:" -ForegroundColor Cyan
for ($i = 0; $i -lt $validBranches.Count; $i++) {
    $displayName = $validBranches[$i]
    if ($displayName -eq $currentActive) {
        $displayName += " (current)"
    }
    Write-Host "[$i] $displayName"
}

$choice = Read-Host "Enter the number of the branch you want to mark as abandoned (or type 'exit' to cancel)"
Check-ForExit $choice
if ($choice -notmatch '^\d+$' -or [int]$choice -ge $validBranches.Count) {
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    Set-Location $global:localServerDir
    exit 1
}

$branchToAbandon = $validBranches[[int]$choice]
if ($branchToAbandon -eq $currentActive) {
    Write-Host "Error: You are currently on branch '$currentActive'. Abandoning the active branch is not allowed." -ForegroundColor Red
    Set-Location $global:localServerDir
    exit 1
}

Write-Host "You selected branch: $branchToAbandon"

# Abandon branch by renaming it with a 'deprecated/' prefix.
$newBranch = "deprecated/$branchToAbandon"
Write-Host "Renaming branch '$branchToAbandon' to '$newBranch'..."
git branch -m $branchToAbandon $newBranch
Write-Host "Deleting old remote branch reference for '$branchToAbandon'..."
git push origin --delete $branchToAbandon 2>$null
Write-Host "Pushing new abandoned branch '$newBranch' to remote..."
git push -u origin $newBranch

Write-Host "Branch '$branchToAbandon' has been marked as abandoned (renamed to '$newBranch')."

# Always explicitly return to the local-server directory.
Set-Location $global:localServerDir
Write-Host "Returned to local-server directory: $global:localServerDir" -ForegroundColor Cyan
