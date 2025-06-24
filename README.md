# Git Manager v3.1.0

A comprehensive interactive Git workflow manager with advanced branch operations, merge conflict detection, compatibility checking, and safety features.

##  Features

- **Interactive Menu System** - Arrow key navigation with detailed descriptions
- **Command-Line Flags** - Direct access to specific operations  
- **Comprehensive Safety Checks** - Multiple confirmation prompts for destructive operations
- **Real-time Repository Status** - Shows current branch, uncommitted changes, unpushed commits
- **Quick Push Workflow** - Add  Commit  Push in one guided sequence
- **Smart Branch Management** - Create, switch, merge, and replace branches safely
- **Intelligent Merge Analysis** - Detects conflicts and compatibility issues before merging
- **Branch Replacement** - Safely replace main branch when branches have diverged significantly
- **Merge Conflict Detection** - Simulates merges to predict conflicts
- **Compatibility Checking** - Analyzes file deletions, dependency mismatches, config changes
- **Branch Divergence Analysis** - Suggests optimal merge vs replace strategies
- **Automatic Backups** - Creates timestamped backups before destructive operations

##  Command-Line Usage

`powershell
# Quick push with message
powershell -File "Git Manager.ps1" -quick -message "Your commit message"

# Show repository status
powershell -File "Git Manager.ps1" -status

# Show commit history  
powershell -File "Git Manager.ps1" -log

# Show help
powershell -File "Git Manager.ps1" -help

# Replace main branch with current branch (DESTRUCTIVE)
powershell -File "Git Manager.ps1" -replace

# Launch interactive menu
powershell -File "Git Manager.ps1"
`

##  Requirements

- **PowerShell 5.0+** (Windows PowerShell or PowerShell Core)
- **Git 2.0+** installed and accessible from command line
- **Git repository** - Must be run from within a git repository
- **Repository write access** for push/merge operations

##  Safety Features

- **Double Confirmation** for destructive operations
- **Automatic Backups** before replacing branches
- **Impact Analysis** showing what commits will be lost/gained
- **Compatibility Checking** for file deletions, dependency conflicts
- **Merge Conflict Detection** before attempting merges

##  When to Use Replace vs Merge

The script suggests "Replace Main Branch" when it detects:
- **50+ total commits** of divergence between branches
- **30+ commits behind** with working branch significantly ahead  
- **3:1 ratio** of ahead:behind commits with 20+ commits ahead
- **20+ structural changes** (major file additions/deletions)

---

** Important**: Always ensure you have backups of important work before using destructive operations. While the script creates automatic backups, having additional backups is recommended for critical projects.
