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
