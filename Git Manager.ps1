# Ultimate Interactive Git Helper Script with Compatibility Checking
# Full-featured git workflow manager with branch operations, merge conflict detection,
# compatibility checking, and comprehensive safety checks to prevent functionality breaks
# Usage: powershell -File "C:\Users\Mike\Documents\Python Scripts\git-push.ps1"

[CmdletBinding()]
param(
    [string]$message = "",
    [switch]$quick,
    [switch]$help,
    [switch]$status,
    [switch]$log,
    [switch]$add,
    [switch]$commit,
    [switch]$push,
    [switch]$version,
    [switch]$replace
)

# Script version
$ScriptVersion = "3.1.0"

# Help function
function Show-Help {
    Write-Host "`n🚀 Ultimate Interactive Git Helper v$ScriptVersion" -ForegroundColor Magenta
    Write-Host "=================================================" -ForegroundColor Magenta
    Write-Host "`nDESCRIPTION:" -ForegroundColor Cyan
    Write-Host "  A comprehensive interactive git workflow manager with branch operations,"
    Write-Host "  merge conflict detection, compatibility checking, and safety checks."
    Write-Host "`nFEATURES:" -ForegroundColor Cyan
    Write-Host "  ✅ Interactive prompts for all operations"
    Write-Host "  ✅ Branch creation, switching, and merging"
    Write-Host "  ✅ Merge conflict detection and warnings"
    Write-Host "  ✅ Compatibility checking (file deletions, version conflicts)"
    Write-Host "  ✅ Dependency mismatch detection"
    Write-Host "  ✅ Safety checks before destructive operations"
    Write-Host "  ✅ Arrow key navigation"
    Write-Host "  ✅ Detailed explanations for each action"
    Write-Host "`nUSAGE:" -ForegroundColor Cyan
    Write-Host "  powershell -File git-push.ps1 [OPTIONS]"
    Write-Host "`nFLAGS:" -ForegroundColor Cyan
    Write-Host "  -quick              Quick push mode (requires -message)"
    Write-Host "  -message <text>     Commit message for quick operations"
    Write-Host "  -help               Show this help menu"
    Write-Host "  -status             Show git status and exit"
    Write-Host "  -log                Show recent commits and exit"
    Write-Host "  -version            Show script version"
    Write-Host "  -replace            Replace main branch with current branch (DESTRUCTIVE)"
    Write-Host "`nNAVIGATION:" -ForegroundColor Cyan
    Write-Host "  Use ↑/↓ arrow keys to navigate menu options"
    Write-Host "  Press Enter to select, Esc to exit"
    Write-Host "  All operations are interactive with confirmation prompts"
    Write-Host "`n"
}

# Version function
function Show-Version {
    Write-Host "Ultimate Interactive Git Helper v$ScriptVersion" -ForegroundColor Green
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

# Get branch selection function
function Select-Branch {
    param([string]$prompt, [string]$currentBranch, [bool]$includeMain = $true)
    
    $branches = @()
    if ($includeMain -and $currentBranch -ne "main") {
        $branches += "main"
    }
    if ($currentBranch -ne "main") {
        $branches += $currentBranch + " (current)"
    }
    
    # Add other branches
    $otherBranches = git branch --format='%(refname:short)' | Where-Object { $_ -ne $currentBranch -and $_ -ne "main" }
    $branches += $otherBranches
    
    Write-Host "`n$prompt" -ForegroundColor Cyan
    for ($i = 0; $i -lt $branches.Count; $i++) {
        Write-Host "  $($i + 1). $($branches[$i])" -ForegroundColor White
    }
    
    do {
        $selection = Read-Host "`nSelect branch number (1-$($branches.Count))"
        $selectionNum = [int]$selection
    } while ($selectionNum -lt 1 -or $selectionNum -gt $branches.Count)
    
    $selectedBranch = $branches[$selectionNum - 1].Replace(" (current)", "")
    return $selectedBranch
}

# Enhanced compatibility checking function
function Test-BranchCompatibility {
    param([string]$sourceBranch, [string]$targetBranch)
    
    Write-Host "`n🔍 Running comprehensive compatibility check..." -ForegroundColor Yellow
    Write-Host "   Analyzing potential functionality breaks when merging $sourceBranch → $targetBranch" -ForegroundColor Gray
    
    $issues = @()
    $warnings = @()
    
    # 1. Check for file deletions (files in target but deleted in source)
    Write-Host "`n📁 Checking for deleted files..." -ForegroundColor Cyan
    $deletedFiles = git diff --name-only --diff-filter=D $targetBranch...$sourceBranch 2>$null
    if ($deletedFiles) {
        $issues += "DELETED_FILES"
        Write-Host "   ⚠️  Files deleted in $sourceBranch that exist in ${targetBranch}:" -ForegroundColor Red
        $deletedFiles | ForEach-Object { 
            Write-Host "      • $_" -ForegroundColor Red
            # Check if it's a critical file
            if ($_ -match "\.(js|ts|py|java|cs|cpp|h)$" -or $_ -match "(config|setup|init)" -or $_ -match "\.(json|yml|yaml|xml)$") {
                $warnings += "Critical file '$_' was deleted - may break imports/dependencies"
            }
        }
    } else {
        Write-Host "   ✅ No file deletions detected" -ForegroundColor Green
    }
    
    # 2. Check for dependency file changes (package.json, requirements.txt, etc.)
    Write-Host "`n📦 Checking dependency files..." -ForegroundColor Cyan
    $dependencyFiles = @("package.json", "requirements.txt", "Pipfile", "composer.json", "pom.xml", "build.gradle", "Cargo.toml", "go.mod")
    
    foreach ($depFile in $dependencyFiles) {
        $sourceFile = git show "$sourceBranch`:$depFile" 2>$null
        $targetFile = git show "$targetBranch`:$depFile" 2>$null
        
        if ($sourceFile -and $targetFile -and $sourceFile -ne $targetFile) {
            $issues += "DEPENDENCY_MISMATCH"
            Write-Host "   ⚠️  Dependency file '$depFile' differs between branches" -ForegroundColor Yellow
            
            # Try to parse version differences for common files
            if ($depFile -eq "package.json") {
                try {
                    $sourceJson = $sourceFile | ConvertFrom-Json
                    $targetJson = $targetFile | ConvertFrom-Json
                    
                    # Check for major version differences
                    if ($sourceJson.dependencies -and $targetJson.dependencies) {
                        $sourceJson.dependencies.PSObject.Properties | ForEach-Object {
                            $depName = $_.Name
                            $sourceVersion = $_.Value
                            $targetVersion = $targetJson.dependencies.$depName
                            
                            if ($targetVersion -and $sourceVersion -ne $targetVersion) {
                                # Extract major version numbers
                                $sourceMajor = if ($sourceVersion -match "(\d+)") { $matches[1] } else { "0" }
                                $targetMajor = if ($targetVersion -match "(\d+)") { $matches[1] } else { "0" }
                                
                                if ($sourceMajor -ne $targetMajor) {
                                    $warnings += "Major version difference in '$depName': $targetVersion → $sourceVersion"
                                }
                            }
                        }
                    }
                } catch {
                    $warnings += "Could not parse package.json for detailed version comparison"
                }
            }
        } elseif ($targetFile -and -not $sourceFile) {
            $warnings += "Dependency file '$depFile' exists in $targetBranch but not in $sourceBranch"
        } elseif ($sourceFile -and -not $targetFile) {
            $warnings += "Dependency file '$depFile' exists in $sourceBranch but not in $targetBranch"
        }
    }
    
    if (-not ($issues -contains "DEPENDENCY_MISMATCH")) {
        Write-Host "   ✅ No dependency conflicts detected" -ForegroundColor Green
    }
    
    # 3. Check for configuration file conflicts
    Write-Host "`n⚙️  Checking configuration files..." -ForegroundColor Cyan
    $configFiles = git diff --name-only $targetBranch...$sourceBranch | Where-Object { 
        $_ -match "(config|settings|env)" -or $_ -match "\.(conf|ini|cfg|properties)$" -or $_ -match "\.env"
    }
    
    if ($configFiles) {
        $issues += "CONFIG_CHANGES"
        Write-Host "   ⚠️  Configuration files modified:" -ForegroundColor Yellow
        $configFiles | ForEach-Object { 
            Write-Host "      • $_" -ForegroundColor Yellow
            $warnings += "Config file '$_' has changes - may affect application behavior"
        }
    } else {
        Write-Host "   ✅ No configuration file conflicts" -ForegroundColor Green
    }
    
    # 4. Check for API/interface changes (look for function/class definitions)
    Write-Host "`n🔧 Checking for potential API changes..." -ForegroundColor Cyan
    $modifiedCodeFiles = git diff --name-only $targetBranch...$sourceBranch | Where-Object { 
        $_ -match "\.(js|ts|py|java|cs|cpp|h|php|rb|go)$" 
    }
    
    if ($modifiedCodeFiles) {
        $apiChanges = 0
        foreach ($file in $modifiedCodeFiles | Select-Object -First 5) {  # Limit to first 5 for performance
            $diff = git diff $targetBranch...$sourceBranch -- $file 2>$null
            if ($diff) {
                # Look for function/method/class definition changes
                $functionChanges = $diff | Select-String -Pattern "^[-+].*\b(function|def|class|public|private|interface|struct)\b"
                if ($functionChanges) {
                    $apiChanges++
                    $warnings += "Potential API changes detected in '$file'"
                }
            }
        }
        
        if ($apiChanges -gt 0) {
            $issues += "API_CHANGES"
            Write-Host "   ⚠️  Potential API/function changes detected in $apiChanges files" -ForegroundColor Yellow
        } else {
            Write-Host "   ✅ No obvious API changes detected" -ForegroundColor Green
        }
    } else {
        Write-Host "   ✅ No code files modified" -ForegroundColor Green
    }
    
    # 5. Check for database migration files
    Write-Host "`n🗃️  Checking for database changes..." -ForegroundColor Cyan
    $dbFiles = git diff --name-only $targetBranch...$sourceBranch | Where-Object { 
        $_ -match "(migration|schema|database)" -or $_ -match "\.(sql|db)$"
    }
    
    if ($dbFiles) {
        $issues += "DATABASE_CHANGES"
        Write-Host "   ⚠️  Database-related files modified:" -ForegroundColor Yellow
        $dbFiles | ForEach-Object { 
            Write-Host "      • $_" -ForegroundColor Yellow
            $warnings += "Database file '$_' changed - may require migration or cause data issues"
        }
    } else {
        Write-Host "   ✅ No database file changes" -ForegroundColor Green
    }
    
    # Return results
    return @{
        HasIssues = $issues.Count -gt 0
        Issues = $issues
        Warnings = $warnings
        Summary = if ($issues.Count -eq 0) { "✅ No compatibility issues detected" } else { "⚠️  $($issues.Count) potential compatibility issues found" }
    }
}

# Check for merge conflicts
function Test-MergeConflicts {
    param([string]$sourceBranch, [string]$targetBranch)
    
    Write-Host "`n🔍 Checking for potential merge conflicts..." -ForegroundColor Yellow
    
    # Simulate merge to check for conflicts
    $mergeBase = git merge-base $sourceBranch $targetBranch 2>$null
    if (-not $mergeBase) {
        return $false
    }
    
    $conflicts = git merge-tree $mergeBase $sourceBranch $targetBranch 2>$null | Select-String "<<<<<<< "
    
    if ($conflicts) {
        Write-Host "⚠️  POTENTIAL MERGE CONFLICTS DETECTED!" -ForegroundColor Red
        Write-Host "   The following files may have conflicts:" -ForegroundColor Yellow
        
        $conflictFiles = git diff --name-only $targetBranch...$sourceBranch
        $conflictFiles | ForEach-Object { Write-Host "   • $_" -ForegroundColor Red }
        
        Write-Host "`n   These files have been modified in both branches." -ForegroundColor Gray
        Write-Host "   You may need to resolve conflicts manually after merging." -ForegroundColor Gray
        
        return $true
    } else {
        Write-Host "✅ No merge conflicts detected. Safe to merge!" -ForegroundColor Green
        return $false
    }
}

# Check for significant branch divergence and suggest replace option
function Test-BranchDivergence {
    param([string]$sourceBranch, [string]$targetBranch)
    
    Write-Host "`n📊 Analyzing branch divergence..." -ForegroundColor Yellow
    
    # Get commit counts
    $aheadCount = git rev-list --count $targetBranch..$sourceBranch 2>$null
    $behindCount = git rev-list --count $sourceBranch..$targetBranch 2>$null
    
    if (-not $aheadCount) { $aheadCount = 0 }
    if (-not $behindCount) { $behindCount = 0 }
    
    Write-Host "   $sourceBranch is $aheadCount commits ahead of $targetBranch" -ForegroundColor Cyan
    Write-Host "   $sourceBranch is $behindCount commits behind $targetBranch" -ForegroundColor Cyan
    
    # Calculate divergence metrics
    $totalDivergence = [int]$aheadCount + [int]$behindCount
    $divergenceRatio = if ($behindCount -gt 0) { [int]$aheadCount / [int]$behindCount } else { [int]$aheadCount }
    
    # Check for significant divergence (suggesting replace might be better than merge)
    $suggestReplace = $false
    $reasons = @()
    
    if ($totalDivergence -gt 50) {
        $suggestReplace = $true
        $reasons += "High total divergence (${totalDivergence} commits)"
    }
    
    if ($behindCount -gt 30 -and $aheadCount -gt $behindCount) {
        $suggestReplace = $true
        $reasons += "Working branch significantly ahead (${aheadCount} vs ${behindCount})"
    }
    
    if ($divergenceRatio -gt 3 -and $aheadCount -gt 20) {
        $suggestReplace = $true
        $reasons += "Working branch has evolved substantially (ratio: $([math]::Round($divergenceRatio, 1)):1)"
    }
    
    # Check for structural changes (major file additions/deletions)
    $addedFiles = git diff --name-only --diff-filter=A $targetBranch..$sourceBranch | Measure-Object | Select-Object -ExpandProperty Count
    $deletedFiles = git diff --name-only --diff-filter=D $targetBranch..$sourceBranch | Measure-Object | Select-Object -ExpandProperty Count
    $structuralChanges = $addedFiles + $deletedFiles
    
    if ($structuralChanges -gt 20) {
        $suggestReplace = $true
        $reasons += "Major structural changes (${addedFiles} added, ${deletedFiles} deleted files)"
    }
    
    return @{
        SuggestReplace = $suggestReplace
        AheadCount = $aheadCount
        BehindCount = $behindCount
        TotalDivergence = $totalDivergence
        Reasons = $reasons
        Summary = if ($suggestReplace) { 
            "🔄 Consider replacing $targetBranch with $sourceBranch" 
        } else { 
            "📈 Standard merge should work fine" 
        }
    }
}

# Replace main branch with current branch (DESTRUCTIVE operation)
function Invoke-BranchReplace {
    param([string]$sourceBranch, [string]$targetBranch = "main")
    
    Write-Host "`n🔄 Replace Branch Operation" -ForegroundColor Red
    Write-Host "   This is a DESTRUCTIVE operation that will replace $targetBranch with $sourceBranch" -ForegroundColor Yellow
    Write-Host "   All commits in $targetBranch that are not in $sourceBranch will be LOST!" -ForegroundColor Red
    
    # Safety checks
    if ($sourceBranch -eq $targetBranch) {
        Write-Host "❌ Cannot replace branch with itself!" -ForegroundColor Red
        return $false
    }
    
    # Show what will be lost
    Write-Host "`n📋 Impact Analysis:" -ForegroundColor Magenta
    
    $uniqueToTarget = git log $sourceBranch..$targetBranch --oneline 2>$null
    if ($uniqueToTarget) {
        Write-Host "   ⚠️  Commits that will be LOST from $targetBranch:" -ForegroundColor Red
        $uniqueToTarget | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
    } else {
        Write-Host "   ✅ No commits will be lost (all $targetBranch commits exist in $sourceBranch)" -ForegroundColor Green
    }
    
    $uniqueToSource = git log $targetBranch..$sourceBranch --oneline 2>$null
    if ($uniqueToSource) {
        Write-Host "   📈 New commits that will be added to $targetBranch:" -ForegroundColor Green
        $uniqueToSource | Select-Object -First 10 | ForEach-Object { Write-Host "      $_" -ForegroundColor Green }
        if (($uniqueToSource | Measure-Object).Count -gt 10) {
            Write-Host "      ... and $((($uniqueToSource | Measure-Object).Count) - 10) more commits" -ForegroundColor Gray
        }
    }
    
    # Multiple confirmation prompts for safety
    Write-Host "`n" + "="*70 -ForegroundColor Red
    Write-Host "⚠️  FINAL WARNING: DESTRUCTIVE OPERATION" -ForegroundColor Red
    Write-Host "="*70 -ForegroundColor Red
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Create backup branch: $targetBranch-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -ForegroundColor White
    Write-Host "  2. Force push $sourceBranch to replace $targetBranch" -ForegroundColor White
    Write-Host "  3. Update local $targetBranch to match remote" -ForegroundColor White
    
    # First confirmation
    if (-not (Confirm-Action "Do you understand this is DESTRUCTIVE and will replace $targetBranch?" "This cannot be easily undone")) {
        Write-Host "❌ Operation cancelled." -ForegroundColor Yellow
        return $false
    }
    
    # Second confirmation with typing requirement
    Write-Host "`n🔐 Security Confirmation Required" -ForegroundColor Red
    Write-Host "   Type 'REPLACE $targetBranch' exactly to confirm:" -ForegroundColor Yellow
    $confirmation = Read-Host "   Confirmation"
    
    if ($confirmation -ne "REPLACE $targetBranch") {
        Write-Host "❌ Confirmation failed. Operation cancelled." -ForegroundColor Red
        return $false
    }
    
    # Execute the replacement
    Write-Host "`n🔄 Executing branch replacement..." -ForegroundColor Yellow
    
    try {
        # Step 1: Create backup branch
        $backupBranch = "$targetBranch-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "   1️⃣ Creating backup branch: $backupBranch" -ForegroundColor Cyan
        git branch $backupBranch $targetBranch
        git push origin $backupBranch
        Write-Host "      ✅ Backup created and pushed to remote" -ForegroundColor Green
        
        # Step 2: Force push source branch to target
        Write-Host "   2️⃣ Force pushing $sourceBranch to replace $targetBranch" -ForegroundColor Cyan
        git push origin $sourceBranch:$targetBranch --force-with-lease
        Write-Host "      ✅ Remote $targetBranch updated" -ForegroundColor Green
        
        # Step 3: Update local target branch
        Write-Host "   3️⃣ Updating local $targetBranch branch" -ForegroundColor Cyan
        git checkout $targetBranch
        git reset --hard origin/$targetBranch
        Write-Host "      ✅ Local $targetBranch updated" -ForegroundColor Green
        
        # Step 4: Clean up source branch if it's not main
        if ($sourceBranch -ne "main") {
            Write-Host "   4️⃣ Cleaning up source branch $sourceBranch" -ForegroundColor Cyan
            if (Confirm-Action "Delete the source branch '$sourceBranch'?" "It's now merged into $targetBranch") {
                git branch -d $sourceBranch 2>$null
                git push origin --delete $sourceBranch 2>$null
                Write-Host "      ✅ Source branch cleaned up" -ForegroundColor Green
            } else {
                Write-Host "      ⏭️  Source branch kept" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`n🎉 Branch replacement completed successfully!" -ForegroundColor Green
        Write-Host "   📋 Summary:" -ForegroundColor Cyan
        Write-Host "      • $targetBranch now contains all changes from $sourceBranch" -ForegroundColor White
        Write-Host "      • Backup available at: $backupBranch" -ForegroundColor White
        Write-Host "      • You are now on the updated $targetBranch branch" -ForegroundColor White
        
        return $true
        
    } catch {
        Write-Host "`n❌ Error during branch replacement: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   The backup branch '$backupBranch' has been created for safety." -ForegroundColor Yellow
        return $false
    }
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
    Write-Host "   Use 'git-push.ps1 -help' for usage information." -ForegroundColor Yellow
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

# Handle command-line flags (keeping existing functionality)
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

if ($replace) {
    Write-Host "`n🔄 Replace mode activated..." -ForegroundColor Red
    Write-Host "   This will replace main branch with current branch ($currentBranch)" -ForegroundColor Yellow
    
    if ($currentBranch -eq "main") {
        Write-Host "❌ ERROR: Cannot replace main with itself! Switch to a different branch first." -ForegroundColor Red
        exit 1
    }
    
    $success = Invoke-BranchReplace $currentBranch "main"
    if ($success) {
        Write-Host "✅ Branch replacement completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Branch replacement failed or was cancelled." -ForegroundColor Red
    }
    exit 0
}

# Interactive menu with enhanced options
$menuItems = @(
    @{
        Name = "Quick Push (Add → Commit → Push)"
        Description = "Stages all files, commits with your message, and pushes to $currentBranch. Interactive prompts guide you through each step."
        Action = "quick"
    },
    @{
        Name = "Add Files to Staging"
        Description = "Choose which files to stage: all files, specific files, or view changes first. Shows exactly what will be staged."
        Action = "add"
    },
    @{
        Name = "Commit Staged Files"
        Description = "Create a commit with staged files. Prompts for commit message and shows files being committed."
        Action = "commit"
    },
    @{
        Name = "Push to Remote"
        Description = "Upload commits to remote repository. Shows which commits will be pushed and confirms target branch."
        Action = "push"
    },
    @{
        Name = "Create New Branch"
        Description = "Create a new branch from current branch or main. Prompts for branch name and source branch selection."
        Action = "newbranch"
    },
    @{
        Name = "Switch Branch"
        Description = "Switch to a different branch. Shows all available branches and warns about uncommitted changes."
        Action = "switchbranch"
    },
    @{
        Name = "Merge Branch (with Compatibility Check)"
        Description = "Merge another branch with comprehensive compatibility checking. Detects file deletions, version conflicts, and potential breaks."
        Action = "merge"
    },
    @{
        Name = "Replace Main Branch (DESTRUCTIVE)"
        Description = "Replace main branch entirely with current branch. Creates backup and force-pushes. Use when branches have diverged significantly."
        Action = "replace"
    },
    @{
        Name = "Pull Latest Changes"
        Description = "Fetch and merge latest changes from remote. Shows what changes will be pulled."
        Action = "pull"
    },
    @{
        Name = "View Repository Status"
        Description = "Shows detailed status: modified files, staged files, branch info, and remote status."
        Action = "status"
    },
    @{
        Name = "View Commit History"
        Description = "Display commit history with graph visualization. Shows last 15 commits with branch relationships."
        Action = "log"
    },
    @{
        Name = "Stash Changes"
        Description = "Temporarily save uncommitted changes. Useful when switching branches with unsaved work."
        Action = "stash"
    },
    @{
        Name = "Show Help & Commands"
        Description = "Display comprehensive help, command-line flags, and usage examples."
        Action = "help"
    },
    @{
        Name = "Exit Application"
        Description = "Close the git helper and return to command prompt."
        Action = "exit"
    }
)

$selectedIndex = 0

function Show-Menu {
    param($items, $selected)
    
    Clear-Host
    Write-Host "`n🚀 Ultimate Interactive Git Helper v$ScriptVersion" -ForegroundColor Magenta
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
        
        Write-Host "$prefix$($i + 1). $($items[$i].Name)" -ForegroundColor $color -BackgroundColor $bgColor
        
        if ($i -eq $selected) {
            Write-Host "   💡 $($items[$i].Description)" -ForegroundColor Gray
            Write-Host ""
        }
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
            $selectedAction = $menuItems[$selectedIndex].Action
            Clear-Host
            
            switch ($selectedAction) {
                "quick" {
                    Write-Host "⚡ Quick Push Workflow" -ForegroundColor Yellow
                    Write-Host "   Complete add → commit → push sequence with guided prompts`n" -ForegroundColor Gray
                    
                    # Show what will be added
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
                                } else {
                                    Write-Host "📤 Commit created but not pushed. Use 'Push to Remote' option later." -ForegroundColor Yellow
                                }
                            } else {
                                Write-Host "❌ Commit cancelled - no message provided" -ForegroundColor Red
                            }
                        }
                    } else {
                        Write-Host "ℹ️  No changes to commit" -ForegroundColor Blue
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                "add" {
                    Write-Host "📁 Add Files to Staging Area" -ForegroundColor Yellow
                    Write-Host "   Select which files to stage for the next commit`n" -ForegroundColor Gray
                    
                    $modifiedFiles = git status --porcelain
                    if ($modifiedFiles) {
                        Write-Host "Modified files:" -ForegroundColor Cyan
                        $modifiedFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
                        
                        Write-Host "`nOptions:" -ForegroundColor Cyan
                        Write-Host "  1. Add all files" -ForegroundColor White
                        Write-Host "  2. Add specific files (interactive)" -ForegroundColor White
                        Write-Host "  3. View detailed changes first" -ForegroundColor White
                        
                        $choice = Read-Host "`nSelect option (1-3)"
                        
                        switch ($choice) {
                            "1" {
                                git add .
                                Write-Host "✅ All files added to staging area" -ForegroundColor Green
                            }
                            "2" {
                                git add -i
                            }
                            "3" {
                                git diff
                                Read-Host "`nPress Enter to continue"
                            }
                        }
                    } else {
                        Write-Host "ℹ️  No changes to stage" -ForegroundColor Blue
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                "commit" {
                    Write-Host "📝 Commit Staged Files" -ForegroundColor Yellow
                    Write-Host "   Create a commit with currently staged files`n" -ForegroundColor Gray
                    
                    $stagedFiles = git diff --cached --name-only
                    if ($stagedFiles) {
                        Write-Host "Files to be committed:" -ForegroundColor Cyan
                        $stagedFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                        
                        $commitMessage = Read-Host "`n📝 Enter commit message"
                        if ($commitMessage) {
                            git commit -m $commitMessage
                            Write-Host "✅ Commit created successfully!" -ForegroundColor Green
                        } else {
                            Write-Host "❌ Commit cancelled - no message provided" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "ℹ️  No staged files to commit" -ForegroundColor Blue
                        Write-Host "   Use 'Add Files to Staging' first" -ForegroundColor Gray
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                "push" {
                    Write-Host "📤 Push to Remote Repository" -ForegroundColor Yellow
                    Write-Host "   Upload local commits to remote branch`n" -ForegroundColor Gray
                    
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
                
                "newbranch" {
                    Write-Host "🌿 Create New Branch" -ForegroundColor Yellow
                    Write-Host "   Create and optionally switch to a new branch`n" -ForegroundColor Gray
                    
                    $branchName = Read-Host "Enter new branch name"
                    if ($branchName) {
                        $sourceBranch = Select-Branch "Create branch from:" $currentBranch
                        
                        Write-Host "`nCreating branch '$branchName' from '$sourceBranch'" -ForegroundColor Cyan
                        git checkout $sourceBranch
                        git checkout -b $branchName
                        
                        Write-Host "✅ Branch '$branchName' created and switched to" -ForegroundColor Green
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                "switchbranch" {
                    Write-Host "🔄 Switch Branch" -ForegroundColor Yellow
                    Write-Host "   Switch to a different branch`n" -ForegroundColor Gray
                    
                    if ($hasUncommittedChanges) {
                        Write-Host "⚠️  You have uncommitted changes!" -ForegroundColor Red
                        Write-Host "   Switching branches will lose these changes unless committed or stashed." -ForegroundColor Yellow
                        
                        if (-not (Confirm-Action "Continue switching branches?" "Uncommitted changes will be lost")) {
                            Read-Host "`nPress Enter to continue"
                            continue
                        }
                    }
                    
                    $targetBranch = Select-Branch "Switch to branch:" $currentBranch
                    
                    if ($targetBranch -ne $currentBranch) {
                        git checkout $targetBranch
                        Write-Host "✅ Switched to branch '$targetBranch'" -ForegroundColor Green
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                "merge" {
                    Write-Host "🔀 Interactive Branch Merge with Compatibility Check" -ForegroundColor Yellow
                    Write-Host "   Merge another branch into current branch ($currentBranch) with safety analysis`n" -ForegroundColor Gray
                    
                    $sourceBranch = Select-Branch "Select branch to merge INTO $currentBranch:" $currentBranch $false
                    
                    Write-Host "`nMerge operation:" -ForegroundColor Cyan
                    Write-Host "  Source: $sourceBranch (will be merged)" -ForegroundColor White
                    Write-Host "  Target: $currentBranch (current branch)" -ForegroundColor Green
                    Write-Host "  Result: $currentBranch will contain changes from both branches" -ForegroundColor Gray
                    
                    # Run comprehensive checks
                    Write-Host "`n" + "="*60 -ForegroundColor Magenta
                    Write-Host "🛡️  RUNNING COMPREHENSIVE SAFETY ANALYSIS" -ForegroundColor Magenta
                    Write-Host "="*60 -ForegroundColor Magenta
                    
                    # Check for branch divergence first
                    $divergenceResult = Test-BranchDivergence $sourceBranch $currentBranch
                    
                    # Check for merge conflicts
                    $hasConflicts = Test-MergeConflicts $sourceBranch $currentBranch
                    
                    # Check for compatibility issues
                    $compatibilityResult = Test-BranchCompatibility $sourceBranch $currentBranch
                    
                    # Display summary
                    Write-Host "`n" + "="*60 -ForegroundColor Magenta
                    Write-Host "📋 ANALYSIS SUMMARY" -ForegroundColor Magenta
                    Write-Host "="*60 -ForegroundColor Magenta
                    
                    Write-Host "`n📊 Branch Divergence: " -NoNewline
                    if ($divergenceResult.SuggestReplace) {
                        Write-Host "⚠️  SIGNIFICANT" -ForegroundColor Red
                        Write-Host "   $($divergenceResult.Summary)" -ForegroundColor Yellow
                        $divergenceResult.Reasons | ForEach-Object {
                            Write-Host "   • $_" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "✅ MANAGEABLE" -ForegroundColor Green
                        Write-Host "   $($divergenceResult.Summary)" -ForegroundColor Green
                    }
                    
                    Write-Host "`n🔀 Merge Conflicts: " -NoNewline
                    if ($hasConflicts) {
                        Write-Host "⚠️  DETECTED" -ForegroundColor Red
                    } else {
                        Write-Host "✅ NONE" -ForegroundColor Green
                    }
                    
                    Write-Host "🛡️  Compatibility: " -NoNewline
                    if ($compatibilityResult.HasIssues) {
                        Write-Host "⚠️  ISSUES FOUND" -ForegroundColor Red
                    } else {
                        Write-Host "✅ COMPATIBLE" -ForegroundColor Green
                    }
                    
                    if ($compatibilityResult.Warnings.Count -gt 0) {
                        Write-Host "`n⚠️  POTENTIAL ISSUES TO REVIEW:" -ForegroundColor Yellow
                        $compatibilityResult.Warnings | ForEach-Object {
                            Write-Host "   • $_" -ForegroundColor Yellow
                        }
                    }
                    
                    Write-Host "`n$($compatibilityResult.Summary)" -ForegroundColor $(if ($compatibilityResult.HasIssues) { "Yellow" } else { "Green" })
                    
                    # Suggest replace option if appropriate
                    if ($divergenceResult.SuggestReplace -and $currentBranch -eq "main") {
                        Write-Host "`n" + "="*60 -ForegroundColor Blue
                        Write-Host "💡 ALTERNATIVE RECOMMENDATION" -ForegroundColor Blue
                        Write-Host "="*60 -ForegroundColor Blue
                        Write-Host "Given the significant divergence, you might consider:" -ForegroundColor Cyan
                        Write-Host "   🔄 Replace main branch with $sourceBranch instead of merging" -ForegroundColor White
                        Write-Host "   📋 This would be cleaner and avoid complex merge conflicts" -ForegroundColor White
                        Write-Host "   🛡️  A backup of main would be created automatically" -ForegroundColor White
                        
                        Write-Host "`nOptions:" -ForegroundColor Cyan
                        Write-Host "  1. Continue with merge (current plan)" -ForegroundColor White
                        Write-Host "  2. Switch to replace operation instead" -ForegroundColor White
                        Write-Host "  3. Cancel and decide later" -ForegroundColor White
                        
                        $choice = Read-Host "`nSelect option (1-3)"
                        
                        switch ($choice) {
                            "2" {
                                Write-Host "`n🔄 Switching to replace operation..." -ForegroundColor Yellow
                                $success = Invoke-BranchReplace $sourceBranch $currentBranch
                                Read-Host "`nPress Enter to continue"
                                continue
                            }
                            "3" {
                                Write-Host "❌ Operation cancelled." -ForegroundColor Yellow
                                Read-Host "`nPress Enter to continue"
                                continue
                            }
                            default {
                                Write-Host "`n📋 Continuing with merge operation..." -ForegroundColor Cyan
                            }
                        }
                    }
                    
                    # Decision point for merge
                    $shouldProceed = $true
                    
                    if ($hasConflicts -or $compatibilityResult.HasIssues) {
                        Write-Host "`n" + "="*60 -ForegroundColor Red
                        Write-Host "⚠️  WARNING: POTENTIAL ISSUES DETECTED" -ForegroundColor Red
                        Write-Host "="*60 -ForegroundColor Red
                        
                        if ($hasConflicts) {
                            Write-Host "`n🔥 Merge conflicts will need manual resolution" -ForegroundColor Red
                        }
                        
                        if ($compatibilityResult.HasIssues) {
                            Write-Host "`n💥 Compatibility issues may break functionality:" -ForegroundColor Red
                            $compatibilityResult.Issues | ForEach-Object {
                                switch ($_) {
                                    "DELETED_FILES" { Write-Host "   • Files deleted in source branch may break dependencies" -ForegroundColor Red }
                                    "DEPENDENCY_MISMATCH" { Write-Host "   • Package/dependency versions differ between branches" -ForegroundColor Red }
                                    "CONFIG_CHANGES" { Write-Host "   • Configuration files have conflicting changes" -ForegroundColor Red }
                                    "API_CHANGES" { Write-Host "   • Potential API/function signature changes detected" -ForegroundColor Red }
                                    "DATABASE_CHANGES" { Write-Host "   • Database schema or migration files modified" -ForegroundColor Red }
                                }
                            }
                        }
                        
                        Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor Cyan
                        Write-Host "   • Review all warnings above before proceeding" -ForegroundColor White
                        Write-Host "   • Consider testing the merge in a separate branch first" -ForegroundColor White
                        Write-Host "   • Have a backup plan to revert if issues occur" -ForegroundColor White
                        Write-Host "   • Ensure all team members are aware of the changes" -ForegroundColor White
                        
                        $shouldProceed = Confirm-Action "Continue with merge despite detected issues?" "This merge may cause functionality problems"
                    }
                    
                    if ($shouldProceed) {
                        if (Confirm-Action "Proceed with merging '$sourceBranch' into '$currentBranch'?" "Final confirmation before executing merge") {
                            Write-Host "`n🔀 Executing merge..." -ForegroundColor Yellow
                            git merge $sourceBranch
                            
                            # Check if merge was successful
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "`n✅ Merge completed successfully!" -ForegroundColor Green
                                Write-Host "`n📋 POST-MERGE CHECKLIST:" -ForegroundColor Cyan
                                Write-Host "   □ Test critical functionality" -ForegroundColor White
                                Write-Host "   □ Run automated tests if available" -ForegroundColor White
                                Write-Host "   □ Check for runtime errors" -ForegroundColor White
                                Write-Host "   □ Verify configuration settings" -ForegroundColor White
                                if ($compatibilityResult.HasIssues) {
                                    Write-Host "   □ Address compatibility warnings listed above" -ForegroundColor Yellow
                                }
                            } else {
                                Write-Host "`n⚠️  Merge completed with conflicts that need resolution." -ForegroundColor Yellow
                                Write-Host "   Use 'git status' to see conflicted files." -ForegroundColor Gray
                                Write-Host "   Resolve conflicts, then run 'git commit' to complete the merge." -ForegroundColor Gray
                            }
                        } else {
                            Write-Host "❌ Merge cancelled." -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "❌ Merge cancelled due to compatibility concerns." -ForegroundColor Yellow
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                "pull" {
                    Write-Host "📥 Pull Latest Changes" -ForegroundColor Yellow
                    Write-Host "   Fetch and merge latest changes from remote`n" -ForegroundColor Gray
                    
                    Write-Host "Fetching latest changes..." -ForegroundColor Cyan
                    git fetch origin
                    
                    $behindCommits = git rev-list --count HEAD..origin/$currentBranch 2>$null
                    if ($behindCommits -and $behindCommits -gt 0) {
                        Write-Host "📊 Your branch is $behindCommits commits behind origin/$currentBranch" -ForegroundColor Yellow
                        
                        if (Confirm-Action "Pull and merge these changes?") {
                            git pull origin $currentBranch
                            Write-Host "✅ Pull completed successfully!" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "✅ Your branch is up to date with remote" -ForegroundColor Green
                    }
                    
                    Read-Host "`nPress Enter to continue"
                }
                
                "status" {
                    Write-Host "📊 Repository Status" -ForegroundColor Yellow
                    git status
                    Read-Host "`nPress Enter to continue"
                }
                
                "log" {
                    Write-Host "📜 Commit History" -ForegroundColor Yellow
                    git log --oneline -15 --graph --decorate --all
                    Read-Host "`nPress Enter to continue"
                }
                
                "stash" {
                    Write-Host "💾 Stash Changes" -ForegroundColor Yellow
                    Write-Host "   Temporarily save uncommitted changes`n" -ForegroundColor Gray
                    
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
                
                "help" {
                    Show-Help
                    Read-Host "`nPress Enter to continue"
                }
                
                "exit" {
                    Write-Host "`n👋 Thanks for using Ultimate Interactive Git Helper!" -ForegroundColor Green
                    exit 0
                }
            }
        }
        27 { # Escape
            Write-Host "`n👋 Thanks for using Ultimate Interactive Git Helper!" -ForegroundColor Green
            exit 0
        }
    }
} while ($true) 