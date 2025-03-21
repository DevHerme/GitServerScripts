# CI/CD Project Overview

This repository contains scripts and configurations for a **local development workflow** and a **live deployment workflow**, designed to handle versioning, branching, and zero-downtime deployment (blue-green).

## Repository Structure

ci-cd/ 
├── local-server/ 
│ ├── abandon-branch.ps1 
│ ├── commit.ps1 
│ ├── common.ps1 
│ ├── project-config.json 
│ ├── release.ps1 
│ ├── rename-branch.ps1 
│ ├── start-bugfix.ps1 
│ ├── start-feature.ps1 
│ ├── start-hotfix.ps1 
│ ├── switch-branch.ps1 (optional) 
│ └── README.md (optional, referencing the root README) 
└── live-server/ 
    ├── new-release.ps1 (or webhook-listener.js) 
    ├── rollback-live.ps1 
    ├── skip-deployment.ps1 
    ├── foundry-live-log.txt
    └── README.md (optional, referencing the root README)

    
## Local Server Scripts

- **Branch Creation**  
  - `start-feature.ps1`: Creates a new feature branch using the current version (e.g., `v1.2.3/feature/xyz`), prompting to commit any uncommitted changes.  
  - `start-bugfix.ps1` / `start-hotfix.ps1`: Similar to `start-feature`, but for bugfix/hotfix branches.

- **Commit & Release**  
  - `commit.ps1`: Quickly stages, commits, and pushes all changes with a user-provided message (including guidelines for describing changes and database updates).  
  - `release.ps1`: Merges the current branch into the stable branch, bumps the version (major, minor, or patch), updates the `VERSION` file, tags the release, and pushes to remote.

- **Branch Management**  
  - `abandon-branch.ps1`: Renames the current branch to a `deprecated/` prefix (e.g., `v1.2.3/deprecated/feature/xyz`), deleting the old remote reference so it’s effectively abandoned.  
  - `rename-branch.ps1`: Renames the current branch (e.g., from `v1.2.3/feature/old-name` to `v1.2.3/feature/new-name`), removing the old remote branch reference and pushing the new one.  
  - `switch-branch.ps1` (optional): Lists all available branches (stable, feature, bugfix, hotfix, deprecated) and prompts you to select one to switch to.

- **Shared Helpers**  
  - `common.ps1`: Contains helper functions (like loading `project-config.json`, handling uncommitted changes, switching branches, and creating/pushing new branches).

- **Configuration**  
  - `project-config.json`: Defines your `projectName`, `stableBranch` (usually `main`), and `projectPath` (the local path to the Git repository).

## Live Server Scripts

- **Deployment**  
  - `webhook-listener.js` or `new-release.ps1`: Listens for GitHub webhooks (pushes to `main` or new tags), pulls the latest code, installs dependencies, builds, and spins up a new environment.  
  - If health checks pass, traffic is switched to the new environment (blue-green deployment).

- **Rollback & Skipping**  
  - `rollback-live.ps1`: Instantly reverts traffic to the old environment if the new one fails.  
  - `skip-deployment.ps1`: Prevents repeated deployment attempts if a particular release is failing.

- **Logs**  
  - `foundry-live-log.txt`: Stores deployment steps and errors for troubleshooting.

## Usage & Testing

1. **Configure**  
   - In `local-server/project-config.json`, set `stableBranch` (e.g., `main`) and `projectPath` to your local Git repo location.  
   - Ensure there’s a `VERSION` file in the repo root (e.g., `v0.1.0`).

2. **Local Workflow**  
   - **Create Branches**:  
     - `.\start-feature.ps1` → Creates `vX.Y.Z/feature/YourFeature`.  
     - `.\start-bugfix.ps1` → Creates `vX.Y.Z/bugfix/YourBug`.  
   - **Commit** changes frequently with `.\commit.ps1`.  
   - **Release**:  
     - `.\release.ps1` merges your branch into stable, bumps version, tags, and pushes.

3. **Live Deployment**  
   - A webhook or manual trigger detects new commits/tags on stable (`main`).  
   - The deployment script (Node or PowerShell) pulls the latest, builds, and updates the live environment.  
   - If deployment fails, logs are updated, and a rollback can be triggered if needed.

4. **Branch Management**  
   - **Abandon**: `.\abandon-branch.ps1` to rename the current branch to a `deprecated/` prefix.  
   - **Rename**: `.\rename-branch.ps1` to rename your branch on both local and remote.  
   - **Switch**: `.\switch-branch.ps1` to select a branch from a list (optional).

5. **Further Enhancements**  
   - Integrate a Node.js or Python webhook listener for automated deployments.  
   - Use Liquibase or a similar tool for DB migrations with rollback scripts.  
   - Add email alerts for deployment failures.

## Recommendations

- **Test** all scripts on a dummy or staging repository first.  
- **Document** any environment variables or secrets needed for production.  
- **Iterate**: Add advanced features (like beta deployments or partial auto-retry) after the core pipeline is stable.

## License & Contributions

- This setup is intended for personal or small-team projects but can be adapted for enterprise-level CI/CD.  
- Feel free to fork or modify the scripts to suit your needs. Pull requests and suggestions are welcome.