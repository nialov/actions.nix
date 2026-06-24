{ lib, ... }:

pkgs: ciConfig:
let
  renderModule =
    { config, ... }:
    let
      pythonEnv = pkgs.python3.withPackages (p: [ p.pyyaml ]);
      evaluatedCI = pkgs.writeTextFile {
        name = "evaluated-ci.json";
        text = builtins.toJSON config.workflows;
      };
      cmdLine = lib.cli.toCommandLineShellGNU { } (
        {
          evaluated-ci-path = evaluatedCI;
        }
        // lib.optionalAttrs config.useJJ {
          use-jj = true;
        }
      );
      renderWorkflows =
        (pkgs.writeShellApplication {
          name = "render-workflows";
          runtimeInputs = [ pkgs.git ] ++ lib.optional config.useJJ pkgs.jj;
          text = ''
            ${pythonEnv}/bin/python3 ${../flake-modules/actions-nix/render.py} ${cmdLine} "$@"
          '';
        }).overrideAttrs
          { preferLocalBuild = true; };
    in
    {
      options.build = {
        evaluatedCI = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "Evaluated workflows as JSON.";
        };
        renderWorkflows = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "Wrapper package for rendering workflows.";
        };
        check = lib.mkOption {
          type = lib.types.functionTo lib.types.package;
          readOnly = true;
          description = "Check that rendered workflows are up to date.";
        };
      };

      config.build = {
        inherit evaluatedCI renderWorkflows;
        check =
          src:
          pkgs.runCommandLocal "actions-nix-check"
            { meta.description = "Check that generated workflows are up to date"; }
            ''
              mkdir project
              cd project

              ${renderWorkflows}/bin/render-workflows --no-prepend-git-root

              if [ -d ${src}/.github/workflows ]; then
                diff -r ${src}/.github/workflows .github/workflows
              else
                test ! -e .github/workflows
              fi

              touch $out
            '';
      };
    };
in
lib.evalModules {
  modules = [
    ../flake-modules/actions-nix/ci.nix
    renderModule
    ciConfig
  ];
}
