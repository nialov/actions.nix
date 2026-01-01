{
  perSystem =
    {
      config,
      pkgs,
      lib,
      self',
      ...
    }:
    {

      packages = {
        test-example = pkgs.writeTextFile {
          name = "test-example";
          text =
            builtins.toJSON
              (lib.evalModules {
                modules = [
                  ../flake-modules/actions-nix/ci.nix
                  {
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
                            steps = [
                              { uses = "actions/checkout@v4"; }
                              {
                                uses = "cachix/install-nix-action@v31";
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
