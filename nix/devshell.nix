{
  perSystem = { config, pkgs, ... }: {
    devShells = {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [ pre-commit ];
        shellHook = config.pre-commit.installationScript;
      };
    };
    pre-commit = {
      check.enable = true;
      settings = {
        src = ../.;
        hooks = {
          nixfmt.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          commitizen.enable = true;
          trim-trailing-whitespace = { enable = true; };
        };
      };

    };
  };
}
