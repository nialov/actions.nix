{ config, lib, flake-parts-lib, ... }: {
  options = let inherit (lib) types;
  in {

    flake = flake-parts-lib.mkSubmoduleOptions {
      ci = lib.mkOption {
        type = types.submoduleWith { modules = [ ./ci.nix ]; };
      };
    };
  };
  config = {
    perSystem = { pkgs, self', system, ... }: {
      pre-commit.settings.hooks = {
        render-ci = {
          inherit (config.flake.ci.pre-commit) enable;
          name = "render-ci";
          pass_filenames = false;
          always_run = true;
          description = "Render nix-configured workflow to respective ci file";
          entry = let renderCI = (config.perSystem system).packages.render-ci;
          in "${renderCI}/bin/render-ci";
        };
      };

      packages.render-ci = pkgs.writeShellApplication {
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
      };
    };

  };
}
