{ utils, ... }:

let
  inherit (utils) isTag concatWithSpace;
  steps = {
    actionsCheckout = { uses = "actions/checkout@v4"; };
    DeterminateSystemsNixInstallerAction = {
      uses = "DeterminateSystems/nix-installer-action@v16";
    };
    runNixFlakeCheck = {
      name = "Check flake";
      run = "nix -Lv flake check";
    };
    cachixCachixAction = { uses = "cachix/cachix-action@v16"; };
    runBuildPackageWithPoetry = {
      name = "Build package with poetry";
      run = ''
        nix run .#poetry -- check
        nix run .#poetry -- build
        nix run .#poetry -- publish --dry-run
      '';
    };
    runPublishPackageWithPoetry = {
      name = "Publish distribution to PyPI on tag";
      "if" = isTag;
      run = concatWithSpace [
        "nix run .#poetry -- publish"
        "--username=__token__ --password=\${{ secrets.PYPI_PASSWORD }}"
        "--no-interaction"
      ];
    };
    runNixFastBuild = {
      name = "Run nix-fast-build";
      run = "nix run .#nix-fast-build -- --skip-cached --no-nom";
    };
    runCheckGitTagAndPyprojectToml = {
      name = "Check that version in pyproject.toml is equivalent to tag on tag";
      "if" = isTag;
      run = ''
        nix run .#sync-git-tag-with-poetry
        nix run .#git -- diff --exit-code
      '';
    };
    runCreateIncrementalChangelog = {
      name = "Create incremental changelog";
      run = ''
        nix run .#cut-release-changelog > RELEASE_CHANGELOG.md
      '';
    };
    softpropsActionGhRelease = {
      name = "Publish release on GitHub on tag";
      uses = "softprops/action-gh-release@v2";
      "with" = {
        body_path = "RELEASE_CHANGELOG.md";
        files = ''
          dist/*
        '';
      };
      env = { GITHUB_TOKEN = "\${{ secrets.GITHUB_TOKEN }}"; };
    };

    actionsUploadPagesArtifact = {
      uses = "actions/upload-pages-artifact@v3";

    };
    actionsConfigurePages = {
      uses = "actions/configure-pages@v5";

    };
    actionsDeployPages = {
      uses = "actions/deploy-pages@v4";
      id = "deployment";
    };
    easimonMaximizeBuildSpaceStep = {
      uses = "easimon/maximize-build-space@master";
      "with" = {
        "remove-dotnet" = true;
        "remove-android" = true;
        "remove-haskell" = true;
        "remove-codeql" = true;
        "remove-docker-images" = true;
        "build-mount-path" = "/nix";
        "temp-reserve-mb" = 1024;
        "root-reserve-mb" = 1024;
        "swap-size-mb" = 2048;
      };
    };
    runReOwnNixStep = {
      name = "Reown /nix to root";
      run = "sudo chown -R root /nix";
    };
    runNixFlakeCheckNoBuild = {
      name = "Check flake without building";
      run = "nix -Lv flake check --no-build";
    };
  };

in steps
