# https://flake.parts/dogfood-a-reusable-module
# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
# localFlake:
_localFlake:
# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
{ config, lib, flake-parts-lib, ... }: {
  options = let inherit (lib) types;
  in {

    flake = flake-parts-lib.mkSubmoduleOptions {
      ci = lib.mkOption {
        type = types.submoduleWith { modules = [ ./ci.nix ]; };
        description = ''
          Configuration of actions.
        '';
      };
    };

  };
  config = {
    perSystem = { pkgs, self', ... }: {
      pre-commit.settings.hooks = {
        render-ci = {
          inherit (config.flake.ci.pre-commit) enable;
          name = "render-ci";
          pass_filenames = false;
          always_run = true;
          description = "Render nix-configured workflow to respective ci file";
          entry = let renderCI = self'.packages.render-ci;
          in "${renderCI}/bin/render-ci";
        };
      };

      packages.render-ci = (pkgs.writeShellApplication {
        name = "render-ci";
        text = let
          pythonEnv = pkgs.python3.withPackages (p: [ p.pyyaml ]);
          evaluatedCI = pkgs.writeTextFile {
            name = "evaluated-ci.json";
            text = builtins.toJSON config.flake.ci.workflows;
          };
          cmdLine = lib.cli.toGNUCommandLineShell { } {
            evaluated-ci-path = evaluatedCI;
          };
        in ''
          ${pythonEnv}/bin/python3 ${./render.py} ${cmdLine}
        '';
      }).overrideAttrs { preferLocalBuild = true; };
    };

  };
}
