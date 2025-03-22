# GitServerScripts – CI/CD Pipeline Framework

This project provides a fully-scripted **Git-based CI/CD pipeline**, tailored for both local development and live production environments. All tools are written in **PowerShell** (with optional Node.js for webhook automation).

---

## Directory Structure

```
ci-cd/
├── local-server/          # Git branch mgmt, commit, release (run on dev machine)
│   ├── *.ps1              # Feature/hotfix/bugfix branching, release, abandon, rename
│   ├── project-config.json
│   └── README.md
└── live-server/           # Zero-downtime deployment, rollback, logging (run on server)
    ├── *.ps1 or webhook-listener.js
    ├── foundry-live-log.txt
    └── README.md
```

---

## Key Features

- **Versioned Branching Strategy**:  
  Uses `vX.Y.Z/feature/name`, `bugfix/`, `hotfix/` formats and automates version bumps.

- **Stable Release Management**:  
  Merges to `main`, updates `version.txt`, auto-tags the repo, and pushes to remote.

- **Blue-Green Deployments** (live-server):  
  Allows safe rollouts by switching environments only when health checks pass.

- **Rollback Support**:  
  Instantly revert to the last good release with a single command.

---

## Prerequisites

- Windows PowerShell 5.1+ (or PowerShell Core)
- Git installed and configured
- Node.js (optional, for webhook listener)
- GitHub repository with `main` as default branch

---

## Usage Overview

### Local Server (Development)

> Located in `local-server/`

1. **Start Feature Branch**  
   ```powershell
   ./start-feature.ps1
   ```

2. **Commit Changes**  
   ```powershell
   ./commit.ps1
   ```

3. **Release to Main**  
   ```powershell
   ./release.ps1
   ```

4. **Branch Management**  
   - Abandon: `./abandon-branch.ps1`  
   - Rename: `./rename-branch.ps1`  
   - Switch: `./switch-branch.ps1` *(optional)*

5. **Configuration**  
   Update `project-config.json` to match your working directory and stable branch.

---

### Live Server (Production)

> Located in `live-server/`

- **Trigger Deployment**:  
  Use `new-release.ps1` manually, or configure `webhook-listener.js` with GitHub.

- **Rollback Failed Deployment**:  
  ```powershell
  ./rollback-live.ps1
  ```

- **Skip Future Deploys (temporary freeze)**  
  ```powershell
  ./skip-deployment.ps1
  ```

- **Logs**:  
  See `foundry-live-log.txt` for detailed output and troubleshooting.

---

## Recommended Enhancements

- Add CI integration (e.g., GitHub Actions or Jenkins)
- Automate DB migrations with Liquibase or Flyway
- Add `.env` or secret variable management

---

## Contributing & Licensing

This toolset is built for personal & team automation. Fork freely and adapt it to your infrastructure. PRs and issues are welcome.