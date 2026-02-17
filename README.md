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

### Advanced: control relative path with `--no-prepend-git-root`

By default, workflow files will be rendered relative to the git repo root. To write workflow files relative to the process working directory (CWD), run:

```
nix run .#render-workflows -- --no-prepend-git-root
```

This is useful when you want files output somewhere *other* than the git root (e.g., when scripting or testing in a subdirectory).

#### Passing the flag in pre-commit configuration

If you need to add arguments (such as `--no-prepend-git-root`) to the pre-commit hook invocation, you can do so, e.g., using the `raw.args` option in your Nix flake configuration:

```nix
pre-commit.settings.hooks.render-actions = {
  raw.args = [
    "--no-prepend-git-root"
  ];
};
```

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

## Note on `git-hooks` import collisions

The `actions-nix` module automatically imports `git-hooks`. If you also
explicitly import `git-hooks` in your downstream project, and the versions
differ, this can cause an import collision due to the module options being
defined twice.

**Example of collision potential in your flake:**

```nix
imports = [
  inputs.actions-nix.flakeModules.default
  inputs.git-hooks.flakeModule  # Import may conflict as it is already implemented by actions-nix
];
```

**How to avoid collisions:**

You do not have to import `git-hooks` in your flake if you imported the
`actions-nix` module. Alternatively, configure your flake inputs so that
both your project and `actions-nix` use the same version of `git-hooks`.
For example, you can set your `git-hooks` input to follow the one used
by `actions-nix`, or vice versa:

```nix
actions-nix = {
  url = "github:nialov/actions.nix";
};
git-hooks.follows = "actions-nix/git-hooks";
```

or

```nix
git-hooks = {
  url = "github:cachix/git-hooks.nix";
};

actions-nix = {
  url = "github:nialov/actions.nix";
  inputs.git-hooks.follows = "nix-extra/pre-commit-hooks";
};
```

**Recommended:**

Let `actions-nix` handle the import, and avoid importing `git-hooks`
directly.

## About

This is a work-in-progress project. My plan is to implement all
functionality I need for minimizing action code repetition across my own
various projects.

The aim is to be minimal and allow free-form configuration by users instead of
trying to generate it using logic in this project. Main purpose of this project
is to enable writing action logic in `nix` rather than `yaml`. The
opportunities opened by using `nix` are then mainly left for users to exploit.

## Development

**Format code:**

```sh
nix develop -c pre-commit run --all-files
```

**Check flake and evaluate tests:**

```sh
nix flake check
```

**Test workflow rendering locally:**

```sh
nix run .#render-workflows
```

**Check past commit conventions:**

```sh
git log --oneline
```
