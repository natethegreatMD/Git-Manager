# Simple Interactive Git Manager
# A streamlined git workflow tool that actually works
# Usage: powershell -File "Git Manager Simple.ps1"

[CmdletBinding()]
param(
    [string]$message = "",
    [switch]$quick,
    [switch]$help,
    [switch]$status,
    [switch]$log,
    [switch]$version
)

# Script version
$ScriptVersion = "3.1.1-Simple"

# Help function
function Show-Help {
    Write-Host "`n🚀 Simple Interactive Git Manager v$ScriptVersion" -ForegroundColor Magenta
    Write-Host "=================================================" -ForegroundColor Magenta
    Write-Host "`nFEATURES:" -ForegroundColor Cyan
    Write-Host "  ✅ Interactive menu system"
    Write-Host "  ✅ Quick push workflow"
    Write-Host "  ✅ Branch operations"
    Write-Host "  ✅ Safety confirmations"
    Write-Host "`nUSAGE:" -ForegroundColor Cyan
    Write-Host "  powershell -File 'Git Manager Simple.ps1' [OPTIONS]"
    Write-Host "`nFLAGS:" -ForegroundColor Cyan
    Write-Host "  -quick              Quick push mode (requires -message)"
    Write-Host "  -message <text>     Commit message for quick operations"
    Write-Host "  -help               Show this help menu"
    Write-Host "  -status             Show git status and exit"
    Write-Host "  -log                Show recent commits and exit"
    Write-Host "  -version            Show script version"
    Write-Host "`n"
}

# Version function
function Show-Version {
    Write-Host "Simple Interactive Git Manager v$ScriptVersion" -ForegroundColor Green
    exit 0
}

# Safety confirmation function
function Confirm-Action {
    param([string]$message, [string]$details = "")
    
    Write-Host "`n⚠️  $message" -ForegroundColor Yellow
    if ($details) {
        Write-Host "   $details" -ForegroundColor Gray
    }
    
    do {
        $response = Read-Host "`nDo you want to continue? (y/n)"
        $response = $response.ToLower()
    } while ($response -ne "y" -and $response -ne "n" -and $response -ne "yes" -and $response -ne "no")
    
    return ($response -eq "y" -or $response -eq "yes")
}

# Check for help flag
if ($help) {
    Show-Help
    exit 0
}

# Check for version flag
if ($version) {
    Show-Version
}

# Check if we're in a git repository
if (-not (Test-Path ".git") -and -not (git rev-parse --git-dir 2>$null)) {
    Write-Host "❌ ERROR: Not in a git repository!" -ForegroundColor Red
    Write-Host "   Navigate to a git repository directory first." -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit"
    exit 1
}

# Get current branch and repo info
$currentBranch = git branch --show-current
$repoName = Split-Path (git rev-parse --show-toplevel) -Leaf
$currentDir = Get-Location
$hasUncommittedChanges = (git status --porcelain) -ne $null
$hasUnpushedCommits = (git log origin/$currentBranch..$currentBranch --oneline 2>$null) -ne $null

Write-Host "`n📂 Repository: $repoName" -ForegroundColor Cyan
Write-Host "📍 Directory: $currentDir" -ForegroundColor Cyan
Write-Host "🌿 Current Branch: $currentBranch" -ForegroundColor Green

if ($hasUncommittedChanges) {
    Write-Host "⚠️  Uncommitted changes detected" -ForegroundColor Yellow
}
if ($hasUnpushedCommits) {
    Write-Host "📤 Unpushed commits available" -ForegroundColor Blue
}

# Handle command-line flags
if ($status) {
    Write-Host "`n📊 Git Status:" -ForegroundColor Cyan
    git status
    exit 0
}

if ($log) {
    Write-Host "`n📜 Recent Commits:" -ForegroundColor Cyan
    git log --oneline -10 --graph --decorate
    exit 0
}

if ($quick -and $message) {
    Write-Host "`n⚡ Quick push mode activated..." -ForegroundColor Yellow
    Write-Host "   → Adding all files to staging area" -ForegroundColor Gray
    git add .
    Write-Host "   → Committing with message: '$message'" -ForegroundColor Gray
    git commit -m $message
    Write-Host "   → Pushing to branch: $currentBranch" -ForegroundColor Gray
    git push origin $currentBranch
    Write-Host "✅ Quick push completed successfully!" -ForegroundColor Green
    exit 0
} elseif ($quick -and -not $message) {
    Write-Host "❌ ERROR: -quick flag requires -message parameter" -ForegroundColor Red
    exit 1
}

# Interactive menu
$menuItems = @(
    "Quick Push (Add → Commit → Push)",
    "Add Files to Staging",
    "Commit Staged Files", 
    "Push to Remote",
    "Create New Branch",
    "Switch Branch",
    "Merge Branch",
    "Pull Latest Changes",
    "View Repository Status",
    "View Commit History",
    "Stash Changes",
    "Show Help",
    "Exit"
)

$selectedIndex = 0

function Show-Menu {
    param($items, $selected)
    
    Clear-Host
    Write-Host "`n🚀 Simple Interactive Git Manager v$ScriptVersion" -ForegroundColor Magenta
    Write-Host "=================================================" -ForegroundColor Magenta
    Write-Host "📂 $repoName | 🌿 $currentBranch" -ForegroundColor Cyan
    
    if ($hasUncommittedChanges) {
        Write-Host "⚠️  Uncommitted changes" -ForegroundColor Yellow -NoNewline
    }
    if ($hasUnpushedCommits) {
        Write-Host " | 📤 Unpushed commits" -ForegroundColor Blue -NoNewline
    }
    Write-Host ""
    
    Write-Host "`nUse ↑/↓ arrows to navigate, Enter to select, Esc to exit`n" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $items.Count; $i++) {
        $prefix = if ($i -eq $selected) { "→ " } else { "  " }
        $color = if ($i -eq $selected) { "Green" } else { "White" }
        $bgColor = if ($i -eq $selected) { "DarkGreen" } else { "Black" }
        
        Write-Host "$prefix$($i + 1). $($items[$i])" -ForegroundColor $color -BackgroundColor $bgColor
    }
}

# Interactive menu loop
do {
    Show-Menu $menuItems $selectedIndex
    
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    switch ($key.VirtualKeyCode) {
        38 { # Up arrow
            $selectedIndex = if ($selectedIndex -gt 0) { $selectedIndex - 1 } else { $menuItems.Count - 1 }
        }
        40 { # Down arrow
            $selectedIndex = if ($selectedIndex -lt ($menuItems.Count - 1)) { $selectedIndex + 1 } else { 0 }
        }
        13 { # Enter
            Clear-Host
            
            switch ($selectedIndex) {
                0 { # Quick Push
                    Write-Host "⚡ Quick Push Workflow" -ForegroundColor Yellow
                    
                    $modifiedFiles = git status --porcelain
                    if ($modifiedFiles) {
                        Write-Host "📁 Files to be staged and committed:" -ForegroundColor Cyan
                        $modifiedFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
                        
                        if (Confirm-Action "Stage all these files for commit?") {
                            git add .
                            Write-Host "✅ Files staged successfully" -ForegroundColor Green
                            
                            $commitMessage = Read-Host "`n📝 Enter commit message"
                            if ($commitMessage) {
                                git commit -m $commitMessage
                                Write-Host "✅ Commit created successfully" -ForegroundColor Green
                                
                                if (Confirm-Action "Push to remote branch '$currentBranch'?") {
                                    git push origin $currentBranch
                                    Write-Host "✅ Push completed successfully!" -ForegroundColor Green
                                }
                            }
                        }
                    } else {
                        Write-Host "ℹ️  No changes to commit" -ForegroundColor Blue
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                1 { # Add Files
                    Write-Host "📁 Add Files to Staging Area" -ForegroundColor Yellow
                    
                    $modifiedFiles = git status --porcelain
                    if ($modifiedFiles) {
                        Write-Host "Modified files:" -ForegroundColor Cyan
                        $modifiedFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
                        
                        if (Confirm-Action "Add all files to staging?") {
                            git add .
                            Write-Host "✅ All files added to staging area" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "ℹ️  No changes to stage" -ForegroundColor Blue
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                2 { # Commit
                    Write-Host "📝 Commit Staged Files" -ForegroundColor Yellow
                    
                    $stagedFiles = git diff --cached --name-only
                    if ($stagedFiles) {
                        Write-Host "Files to be committed:" -ForegroundColor Cyan
                        $stagedFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                        
                        $commitMessage = Read-Host "`n📝 Enter commit message"
                        if ($commitMessage) {
                            git commit -m $commitMessage
                            Write-Host "✅ Commit created successfully!" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "ℹ️  No staged files to commit" -ForegroundColor Blue
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                3 { # Push
                    Write-Host "📤 Push to Remote Repository" -ForegroundColor Yellow
                    
                    $unpushedCommits = git log origin/$currentBranch..$currentBranch --oneline 2>$null
                    if ($unpushedCommits) {
                        Write-Host "Commits to be pushed:" -ForegroundColor Cyan
                        $unpushedCommits | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
                        
                        if (Confirm-Action "Push these commits to '$currentBranch'?") {
                            git push origin $currentBranch
                            Write-Host "✅ Push completed successfully!" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "ℹ️  No commits to push - branch is up to date" -ForegroundColor Blue
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                4 { # Create Branch
                    Write-Host "🌿 Create New Branch" -ForegroundColor Yellow
                    
                    $branchName = Read-Host "Enter new branch name"
                    if ($branchName) {
                        git checkout -b $branchName
                        Write-Host "✅ Branch '$branchName' created and switched to" -ForegroundColor Green
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                5 { # Switch Branch
                    Write-Host "🔄 Switch Branch" -ForegroundColor Yellow
                    
                    if ($hasUncommittedChanges) {
                        Write-Host "⚠️  You have uncommitted changes!" -ForegroundColor Red
                        if (-not (Confirm-Action "Continue switching branches?" "Uncommitted changes will be lost")) {
                            Read-Host "`nPress Enter to continue"
                            continue
                        }
                    }
                    
                    Write-Host "Available branches:" -ForegroundColor Cyan
                    git branch
                    
                    $targetBranch = Read-Host "`nEnter branch name to switch to"
                    if ($targetBranch -and $targetBranch -ne $currentBranch) {
                        git checkout $targetBranch
                        Write-Host "✅ Switched to branch '$targetBranch'" -ForegroundColor Green
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                6 { # Merge Branch
                    Write-Host "🔀 Merge Branch" -ForegroundColor Yellow
                    
                    Write-Host "Available branches:" -ForegroundColor Cyan
                    git branch
                    
                    $sourceBranch = Read-Host "`nEnter branch name to merge INTO current branch ($currentBranch)"
                    if ($sourceBranch -and $sourceBranch -ne $currentBranch) {
                        if (Confirm-Action "Merge '$sourceBranch' into '$currentBranch'?") {
                            git merge $sourceBranch
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "✅ Merge completed successfully!" -ForegroundColor Green
                            } else {
                                Write-Host "⚠️  Merge completed with conflicts that need resolution." -ForegroundColor Yellow
                            }
                        }
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                7 { # Pull
                    Write-Host "📥 Pull Latest Changes" -ForegroundColor Yellow
                    
                    if (Confirm-Action "Pull latest changes from remote?") {
                        git pull origin $currentBranch
                        Write-Host "✅ Pull completed!" -ForegroundColor Green
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                8 { # Status
                    Write-Host "📊 Repository Status" -ForegroundColor Yellow
                    git status
                    Read-Host "`nPress Enter to continue"
                }
                
                9 { # Log
                    Write-Host "📜 Commit History" -ForegroundColor Yellow
                    git log --oneline -15 --graph --decorate
                    Read-Host "`nPress Enter to continue"
                }
                
                10 { # Stash
                    Write-Host "💾 Stash Changes" -ForegroundColor Yellow
                    
                    if ($hasUncommittedChanges) {
                        $stashMessage = Read-Host "Enter stash message (optional)"
                        if ($stashMessage) {
                            git stash push -m $stashMessage
                        } else {
                            git stash push
                        }
                        Write-Host "✅ Changes stashed successfully!" -ForegroundColor Green
                    } else {
                        Write-Host "ℹ️  No changes to stash" -ForegroundColor Blue
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                11 { # Help
                    Show-Help
                    Read-Host "`nPress Enter to continue"
                }
                
                12 { # Exit
                    Write-Host "`n👋 Thanks for using Simple Git Manager!" -ForegroundColor Green
                    exit 0
                }
            }
        }
        27 { # Escape
            Write-Host "`n👋 Thanks for using Simple Git Manager!" -ForegroundColor Green
            exit 0
        }
    }
} while ($true) 