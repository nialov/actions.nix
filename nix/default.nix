inputs:
let

  flakePart = inputs.flake-parts.lib.mkFlake { inherit inputs; }
    ({ self, inputs, config, flake-parts-lib, ... }@args:
      let
        inherit (flake-parts-lib) importApply;
        flakeModules = let ci = importApply ./flake-modules/ci args;
        in {
          inherit ci;
          default = ci;
        };

      in {
        systems = [ "x86_64-linux" ];
        imports = [
          inputs.pre-commit-hooks.flakeModule
          # Module definition
          flakeModules.ci
          # Module config for this repository
          ./ci
          ./devshell.nix
        ];
        flake = { inherit self flakeModules; };

      });

in flakePart
