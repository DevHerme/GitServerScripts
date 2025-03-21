# common.ps1
$ErrorActionPreference = 'Stop'

# Set the local-server directory to the folder containing the scripts.
$global:localServerDir = $PSScriptRoot

function Load-ProjectConfig {
    Param (
        [string] $ConfigFilePath
    )
    if (Test-Path $ConfigFilePath) {
        $configContent = Get-Content $ConfigFilePath -Raw
        $config = $configContent | ConvertFrom-Json
        $Script:ProjectName  = $config.projectName
        $Script:StableBranch = $config.stableBranch
        $Script:ProjectPath  = $config.projectPath
        Write-Host "Loaded project config: $($Script:ProjectName)"
    }
    else {
        Write-Host "Config file not found at $ConfigFilePath. Using default values." -ForegroundColor Red
        $Script:ProjectName  = "UnnamedProject"
        $Script:StableBranch = "main"
        $Script:ProjectPath  = (Get-Location).Path
    }
}
function Handle-UncommittedChanges {
    $statusPorcelain = git status --porcelain
    if ($statusPorcelain) {
        Write-Host "Uncommitted changes detected on current branch:" -ForegroundColor Yellow
        
        # Print dashed lines without the full status in between.
        Write-Host "--------------------------------------------------" -ForegroundColor Cyan
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
        }
        else {
            Write-Host "No code differences to display." -ForegroundColor Green
        }
        
        # Print the current branch before prompting.
        $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        Write-Host "You are currently on branch: '$currentBranch'" -ForegroundColor Cyan

        # Prompt for commit with default YES.
        $choice = Read-Host "Would you like to commit these changes? (Y/N) [default=Y]"
        if ([string]::IsNullOrWhiteSpace($choice)) {
            $choice = "Y"
        }
        else {
            Check-ForExit $choice
        }
        
        if ($choice -eq "Y" -or $choice -eq "y") {
            Write-Host "Include in your commit message a summary of changes:" -ForegroundColor Yellow
            $commitMessage = Read-Host "Enter commit message"
            Check-ForExit $commitMessage
            git add .
            $staged = git diff --cached | Out-String
            if (![string]::IsNullOrWhiteSpace($staged)) {
                git commit -m "$commitMessage"
                Write-Host "Changes committed." -ForegroundColor Green
                $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
                git push -u origin $currentBranch
                Write-Host "Changes pushed to remote branch '$currentBranch'." -ForegroundColor Green
            }
            else {
                Write-Host "No changes staged. Skipping commit." -ForegroundColor Red
            }
        }
        elseif ($choice -eq "N" -or $choice -eq "n" -or $choice.ToLower() -eq "no") {
            Write-Host "Commit cancelled. Exiting without rolling back changes." -ForegroundColor Red
            exit
        }
    }
    else {
        Write-Host "No uncommitted changes in the current branch." -ForegroundColor Green
    }
}

function Switch-To-Branch {
    Param (
        [string] $BranchName
    )
    Write-Host "Switching to branch '$BranchName'..."
    git checkout $BranchName | Out-Null 2>&1
    $current = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($current -eq $BranchName) {
        Write-Host "Switched to branch '$BranchName'."
    }
    else {
        Write-Host "Failed to switch to branch '$BranchName'. Please check if the branch exists." -ForegroundColor Red
        exit
    }
}

function Create-And-Push-Branch {
    Param (
        [string] $NewBranchName
    )
    Write-Host "Creating and switching to new branch: $NewBranchName"
    git checkout -b $NewBranchName | Out-Null 2>&1
    Write-Host "Branch '$NewBranchName' created locally."
    Write-Host "Pushing branch '$NewBranchName' to remote..."
    git push -u origin $NewBranchName | Out-Null 2>&1
    Write-Host "Branch '$NewBranchName' pushed to remote."
}

# Check-ForExit: if the user enters "exit" (ignoring case and spaces), revert to the original branch and local-server directory.
function Check-ForExit {
    param(
        [string]$inputString
    )
    if ($inputString.Trim().ToLower() -eq "exit") {
        Write-Host "Exit command received. Reverting to original branch and local-server directory." -ForegroundColor Red
        if ($global:originalBranch) {
            git checkout $global:originalBranch | Out-Null
        }
        Set-Location $global:localServerDir
        exit
    }
}
