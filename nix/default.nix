inputs:
let

  flakePart = inputs.flake-parts.lib.mkFlake { inherit inputs; } (
    {
      self,
      inputs,
      flake-parts-lib,
      withSystem,
      ...
    }:
    let
      inherit (flake-parts-lib) importApply;
      flakeModules =
        let
          actions-nix = importApply ./flake-modules/actions-nix {
            inherit withSystem inputs;
          };
        in
        {
          inherit actions-nix;
          default = actions-nix;
        };
      lib = import ./lib { inherit (inputs.nixpkgs) lib; };

    in
    {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      imports = [
        inputs.git-hooks.flakeModule
        # Module definition
        flakeModules.actions-nix
        # Module config for this repository
        ./ci
        ./devshell.nix
        # Tests
        ./tests
      ];
      flake = { inherit self flakeModules lib; };

    }
  );

in
flakePart
