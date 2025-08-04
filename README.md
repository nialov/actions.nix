# `actions.nix` - generate GitHub/Gitea actions using nix

## Features

-   Contains a `nix` module in `nix/flake-modules/actions-nix/` that converts
    `nix` configuration into GitHub/Gitea action syntax `yaml`
-   Module contains definition of a `pre-commit` hook, using
    `git-hooks.nix`, that converts `actions-nix` configuration into respective
    workflow files in the path defined in configuration

## Why

-   Write your action logic in `nix` and transform that into `yaml`
    actions

-   Use the full capabilities of `nix` to generate logic rather than
    writing it in plain `yaml`

    -   `nix` is a programming language rather than just a configuration
        language like `yaml`
    -   Consequently, it can be used to generate configuration more
        succinctly using functions
    -   Examples and reusable definitions will be added to this project

-   Reuse action definitions you have written in `nix` across repositories by
    using flakes rather than copy-pasting `yaml` across repositories

## Example

See `nix/ci/default.nix` for action configuration in `nix`. This is turned by the
`pre-commit` hook, or by running `nix run .#render-workflows`, into the workflow file
in `.github/workflows/main.yaml`.

## Installation

This project uses `flake-parts`. You need to add the module exposed by this
repository and configure your own workflows.

```nix
  inputs.flake-parts.lib.mkFlake { inherit inputs; }
    ({ self, inputs, config, flake-parts-lib, ... }@args:
      {
        imports = [
          inputs.actions-nix.flakeModules.default
          # Module config for your repository (replace with your own below)
          # ./ci
        ];
      });
```

## Note on `git-hooks` Import Collisions

The `actions-nix` module automatically imports its own version of `git-hooks`.  
If you also explicitly import `git-hooks` in your downstream project, and the versions differ, this can cause an import collision.

**Example of collision:**
```nix
imports = [
  inputs.actions-nix.flakeModules.default
  inputs.git-hooks.flakeModule  # Explicit import (may conflict)
];
```

**How to avoid collisions:**  
You can configure your flake inputs so that both your project and `actions-nix` use the same version of `git-hooks`.  
For example, you can set your `git-hooks` input to follow the one used by `actions-nix`, or vice versa:

```nix
inputs.git-hooks.url = inputs.actions-nix.inputs.git-hooks.url;
```
or
```nix
inputs.actions-nix.inputs.git-hooks.url = inputs.git-hooks.url;
```

**Recommended:**  
Let `actions-nix` handle the import, and avoid importing `git-hooks` directly unless you are certain the versions match.

## About

This is a work-in-progress project. My plan is to implement all
functionality I need for minimizing action code repetition across my own
various projects.

The aim is to be minimal and allow free-form configuration by users instead of
trying to generate it using logic in this project. Main purpose of this project
is to enable writing action logic in `nix` rather than `yaml`. The
opportunities opened by using `nix` are then mainly left for users to exploit.
