# Working Git Manager - Simple and Reliable
# Usage: powershell -File "Git Manager Working.ps1"

param(
    [string]$message = "",
    [switch]$quick,
    [switch]$help,
    [switch]$status,
    [switch]$log,
    [switch]$version,
    [switch]$replace
)

# Script version
$ScriptVersion = "3.2.8-RemoteTracking"

# Check if we're in a git repository
if (-not (Test-Path ".git") -and -not (git rev-parse --git-dir 2>$null)) {
    Write-Host "ERROR: Not in a git repository!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get current info
$currentBranch = git branch --show-current
$repoName = Split-Path (git rev-parse --show-toplevel) -Leaf

Write-Host "`nGit Manager v$ScriptVersion - Repository: $repoName | Branch: $currentBranch" -ForegroundColor Cyan

# Simple confirmation function
function Confirm-Action {
    param([string]$message)
    
    do {
        $response = Read-Host "$message (y/n)"
        $response = $response.ToLower()
    } while ($response -ne "y" -and $response -ne "n")
    
    return ($response -eq "y")
}

# Enhanced error handling function
function Invoke-GitCommand {
    param([string]$command, [string]$description)
    
    Write-Host "Executing: $description" -ForegroundColor Cyan
    try {
        Invoke-Expression $command
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: Command completed with exit code $LASTEXITCODE" -ForegroundColor Yellow
            return $false
        }
        Write-Host "Success: $description completed" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error: $description failed - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Remote branch tracking
function Get-RemoteInfo {
    Write-Host "Remote Information:" -ForegroundColor Cyan
    
    $remotes = git remote -v
    if ($remotes) {
        Write-Host "Configured remotes:" -ForegroundColor White
        $remotes | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
    
    Write-Host "`nRemote branch status:" -ForegroundColor White
    $remoteBranches = git branch -r 2>$null
    if ($remoteBranches) {
        $remoteBranches | ForEach-Object { 
            $branch = $_.Trim()
            if ($branch -notmatch 'origin/HEAD') {
                Write-Host "  $branch" -ForegroundColor Gray
            }
        }
    }
    
    # Check if current branch has upstream
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    if ($upstream) {
        Write-Host "`nCurrent branch tracks: $upstream" -ForegroundColor Green
        
        $ahead = git rev-list --count HEAD...$upstream 2>$null
        $behind = git rev-list --count $upstream...HEAD 2>$null
        
        if ($ahead -gt 0) {
            Write-Host "  Behind by $ahead commits" -ForegroundColor Yellow
        }
        if ($behind -gt 0) {
            Write-Host "  Ahead by $behind commits" -ForegroundColor Blue
        }
        if ($ahead -eq 0 -and $behind -eq 0) {
            Write-Host "  Up to date with remote" -ForegroundColor Green
        }
    } else {
        Write-Host "`nCurrent branch has no upstream tracking" -ForegroundColor Yellow
        if (Confirm-Action "Set upstream for current branch?") {
            Invoke-GitCommand "git push -u origin $currentBranch" "Set upstream tracking"
        }
    }
}

# Basic compatibility checking
function Test-BranchCompatibility {
    param([string]$sourceBranch, [string]$targetBranch)
    
    Write-Host "Running compatibility check..." -ForegroundColor Yellow
    
    $issues = @()
    
    # Check for deleted files
    $deletedFiles = git diff --name-only --diff-filter=D $targetBranch...$sourceBranch 2>$null
    if ($deletedFiles) {
        $issues += "Files deleted in $sourceBranch"
        Write-Host "Warning: Files deleted:" -ForegroundColor Yellow
        $deletedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }
    
    # Check for dependency files
    $dependencyFiles = @("package.json", "requirements.txt", "pom.xml")
    foreach ($depFile in $dependencyFiles) {
        $sourceFile = git show "$sourceBranch`:$depFile" 2>$null
        $targetFile = git show "$targetBranch`:$depFile" 2>$null
        
        if ($sourceFile -and $targetFile -and $sourceFile -ne $targetFile) {
            $issues += "Dependency file '$depFile' differs"
            Write-Host "Warning: $depFile has changes" -ForegroundColor Yellow
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "No compatibility issues detected" -ForegroundColor Green
        return $false
    } else {
        Write-Host "$($issues.Count) potential issues found" -ForegroundColor Yellow
        return $true
    }
}

# Basic merge conflict detection
function Test-MergeConflicts {
    param([string]$sourceBranch, [string]$targetBranch)
    
    Write-Host "Checking for potential merge conflicts..." -ForegroundColor Yellow
    
    $conflictFiles = git diff --name-only $targetBranch...$sourceBranch
    
    if ($conflictFiles) {
        Write-Host "Files that may have conflicts:" -ForegroundColor Yellow
        $conflictFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        return $true
    } else {
        Write-Host "No merge conflicts detected. Safe to merge!" -ForegroundColor Green
        return $false
    }
}

# Enhanced branch management
function Get-BranchInfo {
    Write-Host "Branch Information:" -ForegroundColor Cyan
    Write-Host "Current branch: $currentBranch" -ForegroundColor White
    
    $localBranches = git branch --format="%(refname:short)"
    Write-Host "Local branches: $($localBranches.Count)" -ForegroundColor White
    
    $remoteBranches = git branch -r --format="%(refname:short)" 2>$null
    if ($remoteBranches) {
        Write-Host "Remote branches: $($remoteBranches.Count)" -ForegroundColor White
    }
    
    $unpushedCommits = git log origin/$currentBranch..$currentBranch --oneline 2>$null
    if ($unpushedCommits) {
        Write-Host "Unpushed commits: $($unpushedCommits.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "Branch is up to date with remote" -ForegroundColor Green
    }
}

# Branch replacement function
function Invoke-BranchReplace {
    param([string]$sourceBranch, [string]$targetBranch = "main")
    
    Write-Host "Branch Replace Operation" -ForegroundColor Red
    Write-Host "This will replace $targetBranch with $sourceBranch" -ForegroundColor Yellow
    
    if ($sourceBranch -eq $targetBranch) {
        Write-Host "Cannot replace branch with itself!" -ForegroundColor Red
        return $false
    }
    
    # Show what will happen
    $uniqueToTarget = git log $sourceBranch..$targetBranch --oneline 2>$null
    if ($uniqueToTarget) {
        Write-Host "Commits that will be lost from $targetBranch" -ForegroundColor Red
        $uniqueToTarget | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }
    
    $uniqueToSource = git log $targetBranch..$sourceBranch --oneline 2>$null
    if ($uniqueToSource) {
        Write-Host "New commits that will be added to $targetBranch" -ForegroundColor Green
        $uniqueToSource | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
    }
    
    if (-not (Confirm-Action "This is DESTRUCTIVE. Continue with replacing $targetBranch?")) {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return $false
    }
    
    # Create backup
    $backupBranch = "$targetBranch-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Creating backup branch: $backupBranch" -ForegroundColor Cyan
    git branch $backupBranch $targetBranch
    
    # Replace branch
    Write-Host "Replacing $targetBranch with $sourceBranch" -ForegroundColor Cyan
    $success1 = Invoke-GitCommand "git push origin $sourceBranch`:$targetBranch --force-with-lease" "Force push to remote"
    $success2 = Invoke-GitCommand "git checkout $targetBranch" "Switch to target branch"
    $success3 = Invoke-GitCommand "git reset --hard origin/$targetBranch" "Reset local branch"
    
    if ($success1 -and $success2 -and $success3) {
        Write-Host "Branch replacement completed!" -ForegroundColor Green
        Write-Host "Backup available at: $backupBranch" -ForegroundColor White
        return $true
    } else {
        Write-Host "Branch replacement failed!" -ForegroundColor Red
        return $false
    }
}

# Handle flags
if ($help) {
    Write-Host "`nWorking Git Manager v$ScriptVersion Help:" -ForegroundColor Green
    Write-Host "  -quick -message 'text'  : Quick add, commit, push"
    Write-Host "  -status                 : Show git status"
    Write-Host "  -log                    : Show commit history"
    Write-Host "  -version                : Show version"
    Write-Host "  -replace                : Replace main with current branch"
    Write-Host "  -help                   : Show this help"
    exit 0
}

if ($version) {
    Write-Host "Working Git Manager v$ScriptVersion" -ForegroundColor Green
    exit 0
}

if ($status) {
    git status
    exit 0
}

if ($log) {
    git log --oneline -10 --graph --decorate
    exit 0
}

if ($replace) {
    Write-Host "Replace mode activated..." -ForegroundColor Red
    
    if ($currentBranch -eq "main") {
        Write-Host "ERROR: Cannot replace main with itself! Switch to a different branch first." -ForegroundColor Red
        exit 1
    }
    
    $success = Invoke-BranchReplace $currentBranch "main"
    if ($success) {
        Write-Host "Branch replacement completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Branch replacement failed or was cancelled." -ForegroundColor Red
    }
    exit 0
}

if ($quick -and $message) {
    Write-Host "Quick push mode..." -ForegroundColor Yellow
    $success1 = Invoke-GitCommand "git add ." "Stage all files"
    $success2 = Invoke-GitCommand "git commit -m `"$message`"" "Create commit"
    $success3 = Invoke-GitCommand "git push origin $currentBranch" "Push to remote"
    
    if ($success1 -and $success2 -and $success3) {
        Write-Host "Quick push completed!" -ForegroundColor Green
    } else {
        Write-Host "Quick push failed!" -ForegroundColor Red
    }
    exit 0
}

# Interactive menu
Write-Host "`nSelect an option:" -ForegroundColor Yellow
Write-Host "1. Quick Push (add, commit, push)"
Write-Host "2. Add files"
Write-Host "3. Commit files"
Write-Host "4. Push to remote"
Write-Host "5. Create new branch"
Write-Host "6. Switch branch"
Write-Host "7. Merge branch (with compatibility check)"
Write-Host "8. Replace main branch (DESTRUCTIVE)"
Write-Host "9. Pull latest changes"
Write-Host "10. View status"
Write-Host "11. View log"
Write-Host "12. Branch information"
Write-Host "13. Remote information"
Write-Host "14. Stash changes"
Write-Host "15. Back to main menu"
Write-Host "16. Exit"

$choice = Read-Host "`nEnter choice (1-16)"

switch ($choice) {
    "1" {
        Write-Host "Quick Push Workflow" -ForegroundColor Yellow
        $modifiedFiles = git status --porcelain
        if ($modifiedFiles) {
            Write-Host "Files to be committed:" -ForegroundColor Cyan
            $modifiedFiles | ForEach-Object { Write-Host "  $_" }
            
            if (Confirm-Action "Continue with staging all files?") {
                $commitMsg = Read-Host "Enter commit message"
                if ($commitMsg) {
                    $success1 = Invoke-GitCommand "git add ." "Stage all files"
                    $success2 = Invoke-GitCommand "git commit -m `"$commitMsg`"" "Create commit"
                    
                    if ($success1 -and $success2) {
                        if (Confirm-Action "Push to remote branch '$currentBranch'?") {
                            Invoke-GitCommand "git push origin $currentBranch" "Push to remote"
                        }
                    }
                }
            }
        } else {
            Write-Host "No changes to commit" -ForegroundColor Blue
        }
    }
    
    "2" {
        Write-Host "Add Files" -ForegroundColor Yellow
        $modifiedFiles = git status --porcelain
        if ($modifiedFiles) {
            Write-Host "Modified files:" -ForegroundColor Cyan
            $modifiedFiles | ForEach-Object { Write-Host "  $_" }
            if (Confirm-Action "Add all files to staging?") {
                Invoke-GitCommand "git add ." "Stage all files"
            }
        } else {
            Write-Host "No changes to add" -ForegroundColor Blue
        }
    }
    
    "3" {
        Write-Host "Commit Files" -ForegroundColor Yellow
        $stagedFiles = git diff --cached --name-only
        if ($stagedFiles) {
            Write-Host "Staged files:" -ForegroundColor Cyan
            $stagedFiles | ForEach-Object { Write-Host "  $_" }
            $commitMsg = Read-Host "Enter commit message"
            if ($commitMsg) {
                Invoke-GitCommand "git commit -m `"$commitMsg`"" "Create commit"
            }
        } else {
            Write-Host "No staged files to commit" -ForegroundColor Blue
        }
    }
    
    "4" {
        Write-Host "Push to Remote" -ForegroundColor Yellow
        $unpushedCommits = git log origin/$currentBranch..$currentBranch --oneline 2>$null
        if ($unpushedCommits) {
            Write-Host "Commits to push:" -ForegroundColor Cyan
            $unpushedCommits | ForEach-Object { Write-Host "  $_" }
            if (Confirm-Action "Push these commits to '$currentBranch'?") {
                Invoke-GitCommand "git push origin $currentBranch" "Push to remote"
            }
        } else {
            Write-Host "No commits to push" -ForegroundColor Blue
        }
    }
    
    "5" {
        Write-Host "Create New Branch" -ForegroundColor Yellow
        $branchName = Read-Host "Enter new branch name"
        if ($branchName) {
            $success = Invoke-GitCommand "git checkout -b $branchName" "Create and switch to new branch"
            if ($success) {
                Write-Host "Branch '$branchName' created and switched to" -ForegroundColor Green
            }
        }
    }
    
    "6" {
        Write-Host "Switch Branch" -ForegroundColor Yellow
        Write-Host "Available branches:" -ForegroundColor Cyan
        git branch
        $targetBranch = Read-Host "Enter branch name to switch to"
        if ($targetBranch) {
            Invoke-GitCommand "git checkout $targetBranch" "Switch to branch"
        }
    }
    
    "7" {
        Write-Host "Merge Branch with Compatibility Check" -ForegroundColor Yellow
        Write-Host "Available branches:" -ForegroundColor Cyan
        git branch
        $sourceBranch = Read-Host "Enter branch name to merge INTO current branch ($currentBranch)"
        if ($sourceBranch -and $sourceBranch -ne $currentBranch) {
            
            # Run checks
            $hasConflicts = Test-MergeConflicts $sourceBranch $currentBranch
            $hasCompatibilityIssues = Test-BranchCompatibility $sourceBranch $currentBranch
            
            if ($hasConflicts -or $hasCompatibilityIssues) {
                Write-Host "Warning: Issues detected!" -ForegroundColor Red
                if (-not (Confirm-Action "Continue with merge despite detected issues?")) {
                    Write-Host "Merge cancelled." -ForegroundColor Yellow
                    break
                }
            }
            
            if (Confirm-Action "Merge '$sourceBranch' into '$currentBranch'?") {
                Invoke-GitCommand "git merge $sourceBranch" "Merge branches"
            }
        }
    }
    
    "8" {
        Write-Host "Replace Main Branch (DESTRUCTIVE)" -ForegroundColor Red
        
        if ($currentBranch -eq "main") {
            Write-Host "ERROR: Cannot replace main with itself! Switch to a different branch first." -ForegroundColor Red
        } else {
            $success = Invoke-BranchReplace $currentBranch "main"
            if ($success) {
                Write-Host "Branch replacement completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "Branch replacement failed or was cancelled." -ForegroundColor Red
            }
        }
    }
    
    "9" {
        Write-Host "Pull Latest Changes" -ForegroundColor Yellow
        if (Confirm-Action "Pull latest changes from remote?") {
            Invoke-GitCommand "git pull origin $currentBranch" "Pull from remote"
        }
    }
    
    "10" {
        Write-Host "Repository Status" -ForegroundColor Yellow
        git status
    }
    
    "11" {
        Write-Host "Commit History" -ForegroundColor Yellow
        git log --oneline -15 --graph --decorate
    }
    
    "12" {
        Get-BranchInfo
    }
    
    "13" {
        Get-RemoteInfo
    }
    
    "14" {
        Write-Host "Stash Changes" -ForegroundColor Yellow
        $hasChanges = (git status --porcelain) -ne $null
        if ($hasChanges) {
            $stashMessage = Read-Host "Enter stash message (optional)"
            if ($stashMessage) {
                Invoke-GitCommand "git stash push -m `"$stashMessage`"" "Stash changes with message"
            } else {
                Invoke-GitCommand "git stash push" "Stash changes"
            }
        } else {
            Write-Host "No changes to stash" -ForegroundColor Blue
        }
    }
    
    "15" {
        Write-Host "Returning to main menu..." -ForegroundColor Cyan
        # This will loop back to the menu by not exiting
        & $MyInvocation.MyCommand.Path
        exit 0
    }
    
    "16" {
        Write-Host "Goodbye!" -ForegroundColor Green
        exit 0
    }
    
    default {
        Write-Host "Invalid choice. Please select 1-16." -ForegroundColor Red
        Write-Host "Returning to main menu..." -ForegroundColor Cyan
        & $MyInvocation.MyCommand.Path
        exit 0
    }
}

Read-Host "`nPress Enter to exit" 