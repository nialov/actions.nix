{ lib, ... }:

let
  utils =
    let
      concatWithSpace = lib.concatStringsSep " ";
    in
    {
      inherit concatWithSpace;

      isTag = concatWithSpace [
        "github.event_name == 'push'"
        "&&"
        "startsWith(github.ref, 'refs/tags')"
      ];
      isMaster = concatWithSpace [
        "github.event_name == 'push'"
        "&&"
        "startsWith(github.ref, 'refs/heads/master')"

      ];

    };
  steps = import ./steps.nix { inherit lib utils; };
  jobs = import ./jobs.nix { inherit lib utils; };

in
{

  inherit steps jobs;

}
