{
  flake.ci = {
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
                name = "Check flake";
                run = "nix -Lv flake check";
              }
            ];
          };
        };
      };
    };
  };
}
