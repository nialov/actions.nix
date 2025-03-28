{
  perSystem = { config, pkgs, lib, ... }: {

    packages = {
      test-example = pkgs.writeTextFile {
        name = "test-example";
        text = builtins.toJSON (lib.evalModules {
          modules = [
            ../flake-modules/ci/ci.nix
            {
              pre-commit.enable = true;
              defaults = {
                step = { runs-on = "ubuntu-latest"; };
                jobs = { timeout-minutes = 60; };
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

  };
}
