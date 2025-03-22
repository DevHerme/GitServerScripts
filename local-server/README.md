# GitServerScripts – Local Server Tools

This folder contains PowerShell scripts for managing feature development, version-controlled releases, and branch workflows in a Git-based CI/CD pipeline. These scripts are designed to be used in a **developer's local environment**.

---

## Contents

```
local-server/
├── abandon-branch.ps1       # Rename and deprecate a feature branch
├── commit.ps1               # Stage, commit, and push all local changes
├── common.ps1               # Shared helper functions (e.g., branch switching, config loading)
├── project-config.json      # Local configuration: project path, stable branch, project name
├── release.ps1              # Version bump, merge to stable, push + tag
├── rename-branch.ps1        # Rename a branch and update remote
├── start-feature.ps1        # Create a new versioned feature branch
├── start-bugfix.ps1         # Create a new versioned bugfix branch
├── start-hotfix.ps1         # Create a new versioned hotfix branch
├── switch-branch.ps1        # (Optional) Interactive branch switcher
└── README.md                # You're here
```

---

## Setup

1. **Configure `project-config.json`**

```json
{
  "projectName": "Foundry",
  "stableBranch": "main",
  "projectPath": "C:/Website/Foundry"
}
```

2. **Add a `version.txt` file to your root project folder**
```
v0.1.0
```

---

## Script Usage

### 1. Start a Feature, Bugfix, or Hotfix Branch
Each of these scripts prompts for a name and creates a branch with the format `vX.Y.Z/type/your-description`.

```powershell
./start-feature.ps1
./start-bugfix.ps1
./start-hotfix.ps1
```

### 2. Commit Changes
```powershell
./commit.ps1
```
- Prompts for commit message
- Stages and pushes changes

### 3. Release the Branch
```powershell
./release.ps1
```
- Checks for uncommitted changes and shows a preview
- Prompts for version bump type (major/minor/patch)
- Merges into stable branch
- Updates `version.txt` and creates a Git tag
- Pushes to remote

### 4. Manage or Cleanup Branches
```powershell
./abandon-branch.ps1    # Deprecate current branch
./rename-branch.ps1     # Rename local + remote branch
./switch-branch.ps1     # (Optional) Browse and checkout remote branches
```

---

## Best Practices

- Run all scripts from **PowerShell**, not Git Bash.
- Keep `version.txt` up to date with `release.ps1`.
- Commit frequently and push before using release scripts.
- Avoid using `master` or `main` directly—always branch.

---

## Notes
- Designed to work alongside the `live-server/` folder (deployed separately).
- All scripts are safe to run independently—they handle path switching and config resolution internally.

---

## See Also
- [../live-server/README.md](../live-server/README.md) – Deployment, rollback, and webhook automation scripts.
- [../README.md](../README.md) – Project-wide CI/CD structure and overview.

