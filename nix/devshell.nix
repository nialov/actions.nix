{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [ pre-commit ];
          shellHook = config.pre-commit.installationScript;
        };
      };
      treefmt = {
        flakeFormatter = true;
        flakeCheck = true;
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };
      pre-commit = {
        check.enable = true;
        settings = {
          src = ../.;
          hooks = {
            treefmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            commitizen.enable = true;
            trim-trailing-whitespace = {
              enable = true;
            };
          };
        };

      };
    };
}
