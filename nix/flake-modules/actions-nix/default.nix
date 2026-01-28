# https://flake.parts/dogfood-a-reusable-module
# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
# localFlake:
_localFlake:
# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
{
  config,
  lib,
  flake-parts-lib,
  ...
}:
{
  imports = [ _localFlake.inputs.git-hooks.flakeModule ];
  options =
    let
      inherit (lib) types;
    in
    {

      flake = flake-parts-lib.mkSubmoduleOptions {
        actions-nix = lib.mkOption {
          type = types.submoduleWith { modules = [ ./ci.nix ]; };
          description = ''
            Configuration of actions.
          '';
        };
      };

    };
  config = {
    perSystem =
      { pkgs, ... }:
      {
        # TODO: Should definition not be automatic on flake-module import?
        pre-commit.settings.hooks = {
          render-actions = {
            inherit (config.flake.actions-nix.pre-commit) enable;
            name = "render-workflows";
            pass_filenames = false;
            always_run = true;
            description = "Render nix-configured workflow to respective yaml file";
            # Don't use packages.render-workflows here - its evaluated JSON is
            # frozen at devshell entry time. Instead, run render.py without
            # --evaluated-ci-path so it does a fresh `nix eval` at commit time.
            entry =
              let
                pythonEnv = pkgs.python3.withPackages (p: [ p.pyyaml ]);
              in
              "${pythonEnv}/bin/python3 ${./render.py}";
          };
        };

        # TODO: Should definition not be automatic on flake-module import?
        packages.render-workflows =
          (pkgs.writeShellApplication {
            name = "render-workflows";
            text =
              let
                pythonEnv = pkgs.python3.withPackages (p: [ p.pyyaml ]);
                evaluatedCI = pkgs.writeTextFile {
                  name = "evaluated-ci.json";
                  text = builtins.toJSON config.flake.actions-nix.workflows;
                };
                cmdLine = lib.cli.toCommandLineShellGNU { } {
                  evaluated-ci-path = evaluatedCI;
                };
              in
              ''
                ${pythonEnv}/bin/python3 ${./render.py} ${cmdLine}
              '';
          }).overrideAttrs
            { preferLocalBuild = true; };
      };

  };
}
