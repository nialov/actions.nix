# Tests for the creation of workflow files
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {

      packages = {
      };

      checks =
        let

          mkRenderedTestExample =
            {
              exampleConfig,
              testCmd,
            }:
            let
              evaluatedCI = pkgs.writeTextFile {
                name = "rendered-test-example";
                text =
                  builtins.toJSON
                    (lib.evalModules {
                      modules = [
                        ../flake-modules/actions-nix/ci.nix
                        exampleConfig
                      ];
                    }).config.workflows;
              };
              cmdLine = lib.cli.toCommandLineShellGNU { } {
                evaluated-ci-path = evaluatedCI;
                no-prepend-git-root = true;
              };
              pythonEnv = pkgs.python3.withPackages (p: [ p.pyyaml ]);
            in

            pkgs.runCommand "render-workflows" { } (
              ''
                mkdir $out
                cd $out
                ${pythonEnv}/bin/python3 ${../flake-modules/actions-nix/render.py} ${cmdLine}
              ''
              + testCmd
            );

          baseNixSteps = [
            { uses = "actions/checkout@v4"; }
            {
              uses = "cachix/install-nix-action@v31";
            }
          ];

          nixFlakeCheckValidConfig = {
            pre-commit.enable = true;
            defaultValues = {
              jobs = {
                timeout-minutes = 60;
                runs-on = "ubuntu-latest";
              };
            };
            workflows = {
              ".github/workflows/main.yaml" = {
                jobs = {
                  nix-flake-check = {
                    steps = baseNixSteps ++ [
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
          nixFlakeCheckInvalidConfig = lib.recursiveUpdate nixFlakeCheckValidConfig {
            workflows.".github/workflows/main.yaml".jobs.nix-flake-check.steps = [
              {
                uses = "cachix/install-nix-action@v31";
                this_is_not_good_property = "hello";
              }
            ];
          };
          multipleWorkflowsConfig = lib.recursiveUpdate nixFlakeCheckValidConfig {
            workflows.".github/workflows/format.yaml".jobs.nix-fmt.steps = baseNixSteps ++ [
              {
                name = "Format flake";
                run = "nix fmt";
              }
            ];
          };

        in
        {

          nix-flake-check-example = mkRenderedTestExample {
            exampleConfig = nixFlakeCheckValidConfig;
            testCmd = ''
              echo "Check action yaml file with action-validator"
              ${pkgs.action-validator}/bin/action-validator .github/workflows/main.yaml

              echo "Check for runs-on property job property"
              ${pkgs.yq-go}/bin/yq -e '.jobs.nix-flake-check.runs-on == "ubuntu-latest"' .github/workflows/main.yaml

              # Check that flake check step is in a job
              ${pkgs.yq-go}/bin/yq -e '.jobs.nix-flake-check.steps[].run | select(. == "nix -Lv flake check")' .github/workflows/main.yaml
            '';
          };
          nix-flake-check-invalid-example = mkRenderedTestExample {
            exampleConfig = nixFlakeCheckInvalidConfig;
            testCmd = ''
              echo "Check action yaml file with action-validator which should fail"
              ! ${pkgs.action-validator}/bin/action-validator .github/workflows/main.yaml
            '';
          };
          multiple-workflows-example = mkRenderedTestExample {
            exampleConfig = multipleWorkflowsConfig;
            testCmd = ''
              echo "Check action yaml files with action-validator which both should exist"
              ${pkgs.parallel}/bin/parallel -- ${pkgs.action-validator}/bin/action-validator ::: .github/workflows/main.yaml .github/workflows/format.yaml
            '';
          };

        };

    };
}
