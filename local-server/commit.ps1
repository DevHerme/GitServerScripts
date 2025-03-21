# commit.ps1
. "$PSScriptRoot\common.ps1"

$configFile = Join-Path $PSScriptRoot "project-config.json"
Load-ProjectConfig -ConfigFilePath $configFile

if (-not (Test-Path $Script:ProjectPath)) {
    Write-Host "Project path '$($Script:ProjectPath)' not found. Exiting." -ForegroundColor Red
    Set-Location $global:localServerDir
    exit 1
}

Set-Location $Script:ProjectPath

# Retrieve the current branch and display it prominently.
$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

# Check for uncommitted changes.
$statusPorcelain = git status --porcelain
if ($statusPorcelain) {
    Write-Host "Uncommitted changes detected on current branch:" -ForegroundColor Yellow
    $fullStatus = git status | Out-String
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host $fullStatus -ForegroundColor White
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan

    $codeDiff = git diff | Out-String
    if (![string]::IsNullOrWhiteSpace($codeDiff)) {
         Write-Host "Actual code changes:" -ForegroundColor Magenta
         Write-Host "--------------------------------------------------" -ForegroundColor Cyan
         $diffLines = $codeDiff -split "`n"
         foreach ($line in $diffLines) {
             if ($line.StartsWith('+')) {
                 Write-Host $line -ForegroundColor Green
             }
             elseif ($line.StartsWith('-')) {
                 Write-Host $line -ForegroundColor Red
             }
             else {
                 Write-Host $line -ForegroundColor White
             }
         }
         Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    }
    else {
         Write-Host "No code differences to display." -ForegroundColor Green
    }

    # Display the branch name before the commit prompt.
    Write-Host "You are about to commit changes to branch: '$currentBranch'" -ForegroundColor Cyan

    # Prompt for commit with default YES.
    $choice = Read-Host "Would you like to commit these changes? (Y/N) [default=Y]"
    if ([string]::IsNullOrWhiteSpace($choice)) {
         $choice = "Y"
    }
    $choiceLower = $choice.Trim().ToLower()
    if ($choiceLower -eq "n" -or $choiceLower -eq "no" -or $choiceLower -eq "exit") {
         Write-Host "Commit cancelled. Exiting..." -ForegroundColor Red
         Set-Location $global:localServerDir
         exit
    }
    else {
         Write-Host "Include in your commit message a summary of changes:" -ForegroundColor Yellow
         $commitMessage = Read-Host "Enter commit message"
         Check-ForExit $commitMessage
         git add .
         $staged = git diff --cached | Out-String
         if (![string]::IsNullOrWhiteSpace($staged)) {
             git commit -m "$commitMessage"
             Write-Host "Changes committed." -ForegroundColor Green
             $current = (git rev-parse --abbrev-ref HEAD).Trim()
             git push -u origin $current
             Write-Host "Changes pushed to remote branch '$current'." -ForegroundColor Green
         }
         else {
             Write-Host "No changes staged. Skipping commit." -ForegroundColor Red
         }
    }
}
else {
    Write-Host "No uncommitted changes in the current branch." -ForegroundColor Green
}

# Return to local-server directory.
Set-Location $global:localServerDir
Write-Host "Returned to local-server directory: $global:localServerDir"
