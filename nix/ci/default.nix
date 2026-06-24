{ inputs, ... }:
{
  flake.actions-nix = {
    pre-commit.enable = true;
    # defaults was renamed to defaultValues to avoid conflict
    # with GitHub option
    # https://github.com/nialov/actions.nix/issues/11
    # defaults = {
    defaultValues = {
      jobs = {
        timeout-minutes = 60;
        runs-on = "ubuntu-latest";
      };
    };
    workflows = {
      ".github/workflows/main.yaml" = {
        on = {
          push.branches = [ "master" ];
          workflow_dispatch = { };
          pull_request = { };
        };
        jobs = {
          nix-flake-check = {
            steps = [
              {
                uses = "actions/checkout@v6";
              }
              # Uses step definition from ../lib/steps.nix
              inputs.self.lib.steps.cachixNixInstallerAction
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
