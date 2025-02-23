{
  perSystem = { config, pkgs, ... }: {
    devShells = {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [ pre-commit ];
        shellHook = config.pre-commit.installationScript;
      };
    };
  };
}
