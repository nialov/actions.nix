{ config, lib, ... }:
let
  inherit (lib) types;
  inherit (config) defaultValues;
  filterNullAttrs = lib.filterAttrs (_key: value: value != null);
  mkEmptyDescriptionOption = attrs: lib.mkOption (lib.recursiveUpdate { description = ""; } attrs);
  mkNullStrOption = mkEmptyDescriptionOption {
    type = types.nullOr types.str;
    default = null;
  };
  stepModule = {
    # Allow any attribute definitions
    freeformType = lib.types.attrs;
    options = {
      name = mkNullStrOption;
      uses = mkNullStrOption;
      # TODO: Allow str lines which are then concatted nicely
      run = mkNullStrOption;
      "if" = mkNullStrOption;
      "with" = mkEmptyDescriptionOption {
        type = types.nullOr types.attrs;
        default = null;
      };
      "env" = mkEmptyDescriptionOption {
        type = types.nullOr types.attrs;
        default = null;
      };
    };
  };
  jobModule =
    { config, ... }:
    {
      freeformType = lib.types.attrs;
      options = {
        runs-on = mkEmptyDescriptionOption {
          type = types.nullOr types.str;
          default = if config.steps != null then defaultValues.jobs.runs-on else null;
          defaultText = lib.literalExpression "defaultValues.jobs.runs-on";
        };
        steps = mkEmptyDescriptionOption {
          type = types.nullOr (types.listOf (types.submoduleWith { modules = [ stepModule ]; }));
          default = null;
          apply = steps: if steps != null then builtins.map filterNullAttrs steps else null;
        };
        timeout-minutes = mkEmptyDescriptionOption {
          type = types.nullOr types.int;
          default = defaultValues.jobs.timeout-minutes;
          defaultText = lib.literalExpression "defaultValues.jobs.timeout-minutes";
        };
        needs = mkEmptyDescriptionOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
        };
        strategy = mkEmptyDescriptionOption {
          type = types.nullOr types.attrs;
          default = null;
        };

      };
    };
  workflowsModule = {
    freeformType = lib.types.attrs;
    options = {
      on = lib.mkOption {
        type = types.attrs;
        default = {
          push = { };
          workflow_dispatch = { };
        };
        description = ''
          Trigger(s) to automatically trigger a workflow.
        '';
      };
      jobs = lib.mkOption {
        type = types.attrsOf (types.submoduleWith { modules = [ jobModule ]; });
        apply = lib.mapAttrs' (name: value: lib.nameValuePair name (filterNullAttrs value));
        description = ''
          Configuration of jobs.
        '';
      };
    };
  };

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
      # render-package = {
      #   enable = lib.mkEnableOption ''
      #     addition of a package definition to `perSystem.packages.render-workflows` for rendering workflows.
      #   '';
      # };
      workflows = lib.mkOption {
        type = types.attrsOf (lib.types.submoduleWith { modules = [ workflowsModule ]; });
        default = { };
        description = ''
          Attributes where key is the file in which you want the `yaml`
          configuration and the value is the workflow definition attribute set
          in `nix`. The value is freeform, i.e., you may use any keys and
          values within the attribute set. However, some common keys and values
          have option definitions. If these definitions do not allow syntax
          that is valid within an action framework, e.g. GitHub or Gitea,
          please file an issue.

          See GitHub documentation for GitHub Actions syntax:

          <https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions>

          See Gitea documentation for Gitea Actions syntax:

          <https://docs.gitea.com/next/usage/actions/overview/>
        '';
        example = {
          ".github/workflows/main.yaml" = {
            jobs = {
              nix-flake-check = {
                steps = [
                  { uses = "actions/checkout@v4"; }
                  { uses = "DeterminateSystems/nix-installer-action@v9"; }
                  {
                    name = "Check flake";
                    run = "nix -Lv flake check";
                  }
                ];
              };
            };
          };
        };
      };
      defaultValues = {
        jobs = {
          timeout-minutes = lib.mkOption {
            type = types.nullOr types.int;
            description = "Default value for timeout-minutes for jobs.";
            default = null;
            example = 60;

          };
          runs-on = lib.mkOption {
            type = types.str;
            description = "Default value for runs-on for jobs.";
            default = "ubuntu-latest";
            example = "macos-latest";
          };
        };
      };

    };

    config = { };
    imports =
      # TODO: Does not warn consistently
      # Maybe related to: https://github.com/NixOS/nixpkgs/issues/96006
      [ (lib.mkRenamedOptionModule [ "defaults" ] [ "defaultValues" ]) ];

  };

in
ciModule
