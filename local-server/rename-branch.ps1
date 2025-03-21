# rename-branch.ps1
. "$PSScriptRoot\common.ps1"

$configFile = Join-Path $PSScriptRoot "project-config.json"
Load-ProjectConfig -ConfigFilePath $configFile

if (-not (Test-Path $Script:ProjectPath)) {
    Write-Host "Project path '$($Script:ProjectPath)' not found. Exiting." -ForegroundColor Red
    Set-Location $global:localServerDir
    exit 1
}

Set-Location $Script:ProjectPath

# Get the local branch list and current branch.
$localBranchesRaw = git branch | ForEach-Object { $_.Trim() }
$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()

# Build a list of renamable branches (exclude main)
$renamableBranches = @()
foreach ($line in $localBranchesRaw) {
    # Remove any leading '*' and extra whitespace.
    $branchName = $line -replace '^\*\s+', '' -replace '^\s+', ''
    if ($branchName -eq "main") { continue }
    if ($branchName -eq $currentBranch) {
         $renamableBranches += "$branchName (current)"
    } else {
         $renamableBranches += $branchName
    }
}

if ($renamableBranches.Count -eq 0) {
    Write-Host "No renamable branches found (excluding main). Exiting." -ForegroundColor Red
    Set-Location $global:localServerDir
    exit 1
}

Write-Host "Local branches available for renaming (excluding main):"
for ($i = 0; $i -lt $renamableBranches.Count; $i++) {
    Write-Host "[$i] $($renamableBranches[$i])"
}

$selection = Read-Host "`nEnter the number of the branch you want to rename (or 'exit' to cancel)"
Check-ForExit $selection

if ($selection -notmatch '^\d+$') {
    Write-Host "Invalid selection. Exiting."
    Set-Location $global:localServerDir
    exit 1
}

$selectionIndex = [int]$selection
if ($selectionIndex -lt 0 -or $selectionIndex -ge $renamableBranches.Count) {
    Write-Host "Selection out of range. Exiting."
    Set-Location $global:localServerDir
    exit 1
}

# Remove the " (current)" tag if present.
$selectedBranchEntry = $renamableBranches[$selectionIndex]
$oldBranch = $selectedBranchEntry -replace '\s+\(current\)$', ''

Write-Host "`nSelected branch to rename: $oldBranch"

# Attempt to parse the branch name with the expected pattern: vX.Y.Z/(feature|hotfix|bugfix)/suffix
if ($oldBranch -match '^(v\d+\.\d+\.\d+)\/(feature|hotfix|bugfix)\/(.+)$') {
    $oldVersion = $matches[1]
    $oldType    = $matches[2]
    $oldSuffix  = $matches[3]
} else {
    Write-Host "`nBranch does not match the pattern 'vX.Y.Z/(feature|hotfix|bugfix)/suffix'."
    Write-Host "We'll prompt you for each part manually."
    $oldVersion = Read-Host "Enter the version (e.g., v0.1.0)"
    Check-ForExit $oldVersion
    $oldType = Read-Host "Enter the branch type (feature/hotfix/bugfix)"
    Check-ForExit $oldType
    $oldSuffix = Read-Host "Enter the branch suffix (e.g., MyFeature)"
    Check-ForExit $oldSuffix
}

Write-Host "`nCurrent version: $oldVersion"
Write-Host "Current type: $oldType"
Write-Host "Current suffix: $oldSuffix"

# Allow the user to change the branch type.
$newType = Read-Host "`nEnter a new type (feature/hotfix/bugfix) or leave blank to keep '$oldType'"
Check-ForExit $newType
if ([string]::IsNullOrWhiteSpace($newType)) {
    $newType = $oldType
}

# Allow the user to change the branch suffix.
$newSuffix = Read-Host "`nEnter a new suffix or leave blank to keep '$oldSuffix'"
Check-ForExit $newSuffix
if ([string]::IsNullOrWhiteSpace($newSuffix)) {
    $newSuffix = $oldSuffix
}

# Sanitize the new suffix.
$newSuffixSanitized = ($newSuffix.Trim() -replace '[^a-zA-Z0-9\-_\.]', '-')
$newBranch = "$oldVersion/$newType/$newSuffixSanitized"

Write-Host "`nRenaming branch from '$oldBranch' to '$newBranch'..."

# Switch to the branch to rename.
git checkout $oldBranch | Out-Null

# Handle any uncommitted changes.
Handle-UncommittedChanges

# Rename the branch locally.
git branch -m $oldBranch $newBranch

# If the branch exists on the remote, delete the old remote branch.
git push origin --delete $oldBranch 2>$null

# Push the renamed branch to remote and set upstream.
git push -u origin $newBranch

Write-Host "`nBranch successfully renamed to '$newBranch'."

# Return to the local-server directory.
Set-Location $global:localServerDir
Write-Host "Returned to local-server directory: $global:localServerDir"
