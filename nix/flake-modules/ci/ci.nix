{ config, lib, ... }:
let

  inherit (lib) types;
  filterNullAttrs = lib.filterAttrs (_: value: value != null);
  mkNullStrOption = lib.mkOption {
    type = types.nullOr types.str;
    default = null;
  };
  stepModule = {
    # Allow any attribute definitions
    freeformType = lib.types.attrs;
    options = {
      name = mkNullStrOption;
      uses = mkNullStrOption;
      run = mkNullStrOption;
      "if" = mkNullStrOption;
      "with" = lib.mkOption {
        type = types.nullOr types.attrs;
        default = null;
      };
      "env" = lib.mkOption {
        type = types.nullOr types.attrs;
        default = null;
      };
    };
  };
  jobModule =
    # args:
    {
      internal = true;
      freeformType = lib.types.attrs;
      options = {
        runs-on = lib.mkOption {
          type = types.str;
          default = config.defaults.step.runs-on;
          defaultText = lib.literalExpression "defaults.step.runs-on";
        };
        steps = lib.mkOption {
          type =
            types.listOf (types.submoduleWith { modules = [ stepModule ]; });
          default = [ ];
          apply = builtins.map filterNullAttrs;
        };
        timeout-minutes = lib.mkOption {
          type = types.nullOr types.int;
          default = config.defaults.jobs.timeout-minutes;
          defaultText = lib.literalExpression "defaults.jobs.timeout-minutes";
        };
        needs = lib.mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
        };
        strategy = lib.mkOption {
          type = types.nullOr types.attrs;
          default = null;
        };

      };
    };
  workflowsModule = {
    internal = true;
    freeformType = lib.types.attrs;
    options = {
      on = lib.mkOption {
        type = types.attrs;
        default = {
          push = { };
          workflow_dispatch = { };
        };
      };
      jobs = lib.mkOption {
        type = types.attrsOf (types.submoduleWith { modules = [ jobModule ]; });
        apply = lib.mapAttrs'
          (name: value: lib.nameValuePair name (filterNullAttrs value));
      };
    };
  };

  ciModule = {
    options = {
      pre-commit = {
        enable =
          lib.mkEnableOption "pre-commit generation of workflow yaml files";
      };
      workflows = lib.mkOption {
        type = types.attrsOf
          (lib.types.submoduleWith { modules = [ workflowsModule ]; });
        default = { };
        description = ''
          Attrs where key is the file in which you want the yaml configuration and
          the value is the workflow definition in nix.
        '';
      };
      defaults = {
        step = {
          runs-on = lib.mkOption {
            type = types.str;
            description =
              "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#jobsjob_idruns-on";

          };
        };
        jobs = {
          timeout-minutes = lib.mkOption {
            type = types.int;
            description =
              "https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#jobsjob_idtimeout-minutes";

          };
        };
      };

    };

    config = {

    };

  };

in ciModule
