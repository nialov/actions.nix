{
  perSystem = { config, pkgs, lib, self', ... }: {

    packages = {
      test-example = pkgs.writeTextFile {
        name = "test-example";
        text = builtins.toJSON (lib.evalModules {
          modules = [
            ../flake-modules/actions-nix/ci.nix
            {
              pre-commit.enable = true;
              defaults = {
                jobs = {
                  timeout-minutes = 60;
                  runs-on = "ubuntu-latest";
                };
              };
              workflows = {
                ".github/workflows/main.yaml" = {
                  jobs = {
                    nix-flake-check = {
                      steps = [
                        { uses = "actions/checkout@v4"; }
                        {
                          uses = "DeterminateSystems/nix-installer-action@v9";
                          hello = "there";
                        }
                        {
                          name = "Check flake";
                          run = "nix -Lv flake check";
                        }
                      ];
                    };
                  };
                };
              };
            }

          ];
        }).config;
      };
    };

    checks = self'.packages;

  };
}
