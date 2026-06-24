# https://flake.parts/dogfood-a-reusable-module
# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
# localFlake:
_localFlake:
# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  actionsNixLib = import ../../lib { inherit lib; };
in
{
  imports = [ _localFlake.inputs.git-hooks.flakeModule ];
  options =
    let
      inherit (lib) types;
    in
    {

      flake = flake-parts-lib.mkSubmoduleOptions {
        actions-nix = lib.mkOption {
          type = types.submoduleWith { modules = [ ./ci.nix ]; };
          description = ''
            Configuration of actions.
          '';
        };
      };

    };
  config = {
    perSystem =
      { pkgs, ... }:
      let
        actionsEval = actionsNixLib.evalModule pkgs config.flake.actions-nix;
      in
      {
        # TODO: Should definition not be automatic on flake-module import?
        pre-commit.settings.hooks.render-actions = {
          inherit (config.flake.actions-nix.pre-commit) enable;
          name = "render-workflows";
          pass_filenames = false;
          always_run = true;
          description = "Render nix-configured workflow to respective yaml file";
          entry = "${actionsEval.config.build.renderWorkflows}/bin/render-workflows";
        };

        # TODO: Should definition not be automatic on flake-module import?
        packages.render-workflows = actionsEval.config.build.renderWorkflows;
      };

  };
}
