# AGENTS.md - Development & Test Workflow

- **Format code:**
  ```sh
  nix develop -c pre-commit run --all-files
  ```
- **Check flake and evaluate tests:**
  ```sh
  nix flake check
  ```
- **Test workflow rendering locally:**
  ```sh
  nix run .#render-workflows
  ```
- **Check past commit conventions:**
  ```sh
  git log --oneline
  ```
  This helps you match commit message format for consistency.
