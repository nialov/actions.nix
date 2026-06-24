{ lib, ... }:

ciConfig:
lib.evalModules {
  modules = [
    ../flake-modules/actions-nix/ci.nix
    ciConfig
  ];
}
