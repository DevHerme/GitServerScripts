# release.ps1

. "$PSScriptRoot\common.ps1"

# =========================================================================
# Utility Functions for File-Oriented Diff Display
# =========================================================================

function Get-ChangedFiles {
    $changed = @{}

    git diff --name-status HEAD | ForEach-Object {
        if ($_ -match '^(?<status>A|M|D)\s+(?<filename>.+)$') {
            $changed[$matches.filename.Trim()] = $matches.status
        }
    }

    git status --porcelain | Where-Object { $_ -match '^\?\? ' } | ForEach-Object {
        $file = $_ -replace '^\?\? ', ''
        if (-not $changed.ContainsKey($file)) {
            $changed[$file] = 'A'
        }
    }

    return $changed
}

function Show-Changes {
    param([hashtable]$changedFiles)

    foreach ($file in $changedFiles.Keys) {
        $status = $changedFiles[$file]
        Write-Host "----------------------------------------------------" -ForegroundColor Cyan

        switch ($status) {
            'A' {
                Write-Host "===== [NEW] $file =====" -ForegroundColor Green
                Write-Host "----------------------------------------------------" -ForegroundColor Cyan
                if (Test-Path $file) {
                    Get-Content $file | ForEach-Object {
                        Write-Host "+ $_" -ForegroundColor Green
                    }
                }
            }
            'M' {
                Write-Host "===== [EDIT] $file =====" -ForegroundColor Yellow
                Write-Host "----------------------------------------------------" -ForegroundColor Cyan
                $diffLines = git diff HEAD -- $file | Out-String -Stream
                foreach ($line in $diffLines) {
                    if ($line -match '^diff --git|^index|^--- |^\+\+\+ |^@@ ') { continue }
                    if ($line.StartsWith('+')) {
                        Write-Host $line -ForegroundColor Green
                    } elseif ($line.StartsWith('-')) {
                        Write-Host $line -ForegroundColor Red
                    } else {
                        Write-Host $line -ForegroundColor White
                    }
                }
            }
            'D' {
                Write-Host "===== [DELETED] $file =====" -ForegroundColor Red
                Write-Host "----------------------------------------------------" -ForegroundColor Cyan
                $previousContent = git show HEAD:$file 2>$null
                if ($previousContent) {
                    $previousContent -split "`n" | ForEach-Object {
                        Write-Host "- $_" -ForegroundColor Red
                    }
                }
            }
        }
    }
}

# =========================================================================
# Main Release Script
# =========================================================================

$configFile = Join-Path $PSScriptRoot "project-config.json"
Load-ProjectConfig -ConfigFilePath $configFile

if (-not (Test-Path $Script:ProjectPath)) {
    Write-Host "Project path '$($Script:ProjectPath)' not found. Exiting." -ForegroundColor Red
    exit
}

$originalDirectory = Get-Location
Set-Location $Script:ProjectPath

$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
$global:originalBranch = $currentBranch

if ($currentBranch -eq $Script:StableBranch) {
    Write-Host "You are already on the stable branch '$Script:StableBranch'. Exiting." -ForegroundColor Red
    Set-Location $originalDirectory
    exit
}

$statusPorcelain = git status --porcelain
if ($statusPorcelain) {
    Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan
    Write-Host "Uncommitted changes detected:" -ForegroundColor Yellow
    Write-Host ""
    $changedFiles = Get-ChangedFiles
    Show-Changes -changedFiles $changedFiles

    $commitChoice = Read-Host "Would you like to commit these changes? (Y/yes or N/no) (or type 'exit' to cancel)"
    Check-ForExit $commitChoice
    if ($commitChoice -match '^(y(es)?)$') {
        $commitMessage = Read-Host "Enter commit message"
        Check-ForExit $commitMessage
        git add .
        if (-not [string]::IsNullOrWhiteSpace((git diff --cached | Out-String))) {
            git commit -m "$commitMessage"
            Write-Host "Changes committed." -ForegroundColor Green
        } else {
            Write-Host "No changes staged. Skipping commit." -ForegroundColor Red
        }
    }
    elseif ($commitChoice -match '^(n(o)?)$') {
        $rollbackChoice = Read-Host "Do you want to rollback to the last committed version of this branch? (Y/yes or N/no)"
        Check-ForExit $rollbackChoice
        if ($rollbackChoice -match '^(y(es)?)$') {
            git reset --hard HEAD
            Write-Host "Rolled back uncommitted changes." -ForegroundColor Green
        } else {
            Write-Host "Release cancelled due to uncommitted changes." -ForegroundColor Red
            Set-Location $originalDirectory
            exit
        }
    } else {
        Write-Host "Invalid input. Exiting." -ForegroundColor Red
        Set-Location $originalDirectory
        exit
    }
}

if ($currentBranch -match '^v\d+\.\d+\.\d+/(feature)/') {
    Write-Host "For feature releases:" -ForegroundColor Yellow
    Write-Host "   0: Major release (breaking changes)"
    Write-Host "   1: Minor release (new features, non-breaking)"
    $releaseTypeInput = Read-Host "Enter release type (0 or 1) (or type 'exit' to cancel)"
    Check-ForExit $releaseTypeInput
    switch ($releaseTypeInput) {
        '0' { $versionType = "major" }
        '1' { $versionType = "minor" }
        default {
            Write-Host "Invalid release type entered. Exiting." -ForegroundColor Red
            Set-Location $originalDirectory
            exit
        }
    }
} elseif ($currentBranch -match '^v\d+\.\d+\.\d+/(bugfix|hotfix)/') {
    Write-Host "For bugfix/hotfix releases, the version bump will be a patch update." -ForegroundColor Yellow
    $versionType = "patch"
} else {
    Write-Host "Unrecognized branch type. Exiting." -ForegroundColor Red
    Set-Location $originalDirectory
    exit
}

$versionFile = Join-Path $Script:ProjectPath "version.txt"
$currentVersion = if (Test-Path $versionFile) {
    (Get-Content $versionFile -Raw).Trim()
} else {
    "v0.0.0"
}
Write-Host "Current version: $currentVersion" -ForegroundColor Cyan

if ($currentVersion -notmatch '^v(\d+)\.(\d+)\.(\d+)$') {
    Write-Host "Current version format is invalid. Expected vX.Y.Z. Exiting." -ForegroundColor Red
    Set-Location $originalDirectory
    exit
}
$major, $minor, $patch = $matches[1..3] | ForEach-Object { [int]$_ }

switch ($versionType) {
    'major' { $major++; $minor = 0; $patch = 0 }
    'minor' { $minor++; $patch = 0 }
    'patch' { $patch++ }
    default {
        Write-Host "Invalid version type. Exiting." -ForegroundColor Red
        Set-Location $originalDirectory
        exit
    }
}

$newVersion = "v$major.$minor.$patch"
Write-Host "New version will be: $newVersion" -ForegroundColor Cyan

$finalConfirm = Read-Host "Final confirmation: Merge $currentBranch into $Script:StableBranch and release $newVersion? (Y/yes or N/no) (or type 'exit' to cancel)"
Check-ForExit $finalConfirm
if ($finalConfirm -notmatch '^(y(es)?)$') {
    Write-Host "Release cancelled. Exiting." -ForegroundColor Red
    Set-Location $originalDirectory
    exit
}

Switch-To-Branch $Script:StableBranch

git merge --no-ff $currentBranch -m "Merge $currentBranch into $Script:StableBranch for release $newVersion"
Write-Host "Merged $currentBranch into $Script:StableBranch." -ForegroundColor Green

$newVersion | Out-File -Encoding UTF8 $versionFile

git add $versionFile
git commit -m "Bump version to $newVersion"
Write-Host "Updated version file to $newVersion." -ForegroundColor Green

git tag -a $newVersion -m "Release $newVersion"
Write-Host "Created tag $newVersion." -ForegroundColor Green

git push origin $Script:StableBranch
git push origin $newVersion
Write-Host "Pushed stable branch and new tag to remote." -ForegroundColor Green

Set-Location $originalDirectory
