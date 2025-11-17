{ inputs, ... }:
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
                  ./ci-config.nix
                ];
              }).config;
        };
        test-example-eval-module = pkgs.writeTextFile {
          name = "test-example-eval-module";
          text = builtins.toJSON (inputs.self.lib.evalModule ./ci-config.nix pkgs).config;
        };
      };

      checks = self'.packages;

    };
}
