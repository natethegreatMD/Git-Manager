# Git Manager v3.2.8-RemoteTracking

A comprehensive interactive Git workflow manager with advanced branch operations, merge conflict detection, compatibility checking, remote tracking, and safety features.

## 🚀 Features

- **Interactive Menu System** - Simple numbered menu with back navigation option
- **Command-Line Flags** - Direct access to specific operations  
- **Comprehensive Safety Checks** - Multiple confirmation prompts for destructive operations
- **Remote Branch Tracking** - Monitor upstream relationships and sync status
- **Real-time Repository Status** - Shows current branch, uncommitted changes, unpushed commits
- **Quick Push Workflow** - Add → Commit → Push in one guided sequence
- **Smart Branch Management** - Create, switch, merge, and replace branches safely
- **Intelligent Merge Analysis** - Detects conflicts and compatibility issues before merging
- **Branch Replacement** - Safely replace main branch when branches have diverged significantly
- **Merge Conflict Detection** - Analyzes potential conflicts before merging
- **Compatibility Checking** - Scans for file deletions, dependency mismatches, config changes
- **Enhanced Error Handling** - Detailed error messages and recovery suggestions
- **Stash Management** - Save and manage uncommitted changes
- **Automatic Backups** - Creates timestamped backups before destructive operations

## 📋 Command-Line Usage

```powershell
# Quick push with message
powershell -File "Git Manager Working.ps1" -quick -message "Your commit message"

# Show repository status
powershell -File "Git Manager Working.ps1" -status

# Show commit history  
powershell -File "Git Manager Working.ps1" -log

# Show version
powershell -File "Git Manager Working.ps1" -version

# Show help
powershell -File "Git Manager Working.ps1" -help

# Replace main branch with current branch (DESTRUCTIVE)
powershell -File "Git Manager Working.ps1" -replace

# Launch interactive menu
powershell -File "Git Manager Working.ps1"
```

## 🔧 Requirements

- **PowerShell 5.0+** (Windows PowerShell or PowerShell Core)
- **Git 2.0+** installed and accessible from command line
- **Git repository** - Must be run from within a git repository
- **Repository write access** for push/merge operations

## 🛡️ Safety Features

- **Double Confirmation** for destructive operations
- **Automatic Backups** before replacing branches
- **Impact Analysis** showing what commits will be lost/gained
- **Compatibility Checking** for file deletions, dependency conflicts
- **Merge Conflict Detection** before attempting merges
- **Enhanced Error Handling** with detailed feedback
- **Remote Tracking** to prevent accidental overwrites

## 📊 Menu Options

1. **Quick Push** - Stage, commit, and push in one workflow
2. **Add Files** - Stage modified files for commit
3. **Commit Files** - Commit staged changes with message
4. **Push to Remote** - Push unpushed commits to remote branch
5. **Create New Branch** - Create and switch to new branch
6. **Switch Branch** - Change to existing branch
7. **Merge Branch** - Merge with compatibility and conflict checking
8. **Replace Main Branch** - Destructive replacement with backup
9. **Pull Latest Changes** - Fetch and merge from remote
10. **View Status** - Show git status
11. **View Log** - Show recent commit history
12. **Branch Information** - Detailed branch analysis
13. **Remote Information** - Remote tracking and sync status
14. **Stash Changes** - Save uncommitted work
15. **Back/Exit** - Return to previous menu or exit

## 🔄 When to Use Replace vs Merge

The script helps identify when to use "Replace Main Branch" by analyzing:
- **Commit divergence** between branches
- **File deletion patterns** that might break functionality  
- **Dependency file changes** (package.json, requirements.txt, etc.)
- **Branch ahead/behind ratios**

## ⚠️ Important Notes

- **Always backup important work** before destructive operations
- **Test in development branches** before affecting main/production
- **Review compatibility warnings** carefully before proceeding
- **Use stash feature** to save uncommitted work before switching branches

---

**Version**: 3.2.8-RemoteTracking | **Status**: Stable | **Platform**: PowerShell 5.0+
