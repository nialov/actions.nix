{ lib, ... }:
let
  inherit (lib) types;

  ciModule = {
    options = {
      pre-commit = {
        enable = lib.mkEnableOption ''
          pre-commit generation of workflow yaml files.

          The pre-commit hook, generated using
          [git-hooks.nix](https://github.com/cachix/git-hooks.nix), converts
          `flake.actions-nix.workflows` configuration into respective workflow
          files in the path defined within the configuration, i.e. key in
          `actions-nix.workflows` attribute set
        '';
      };
      useJJ = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use jj (Jujutsu) for repository root detection
          instead of git during workflow rendering. When enabled, jj will be
          used to find the repository root and fallback to git as normal. This
          is useful if you use jj workspaces where there isn't a git root
          available.
        '';
      };
      # render = {
      #   package = lib.mkOption {
      #     type = lib.types.package;
      #     description = "Wrapper package for rendering workflows.";
      #   };
      # };

    };

  };

in
ciModule
