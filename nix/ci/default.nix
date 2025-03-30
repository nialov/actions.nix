{ inputs, ... }: {
  flake.actions-nix = {
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
              {
                uses = "actions/checkout@v4";
              }
              # Uses step definition from ./lib/steps.nix
              inputs.self.lib.steps.DeterminateSystemsNixInstallerAction
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
