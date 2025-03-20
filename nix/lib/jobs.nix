{ utils, ... }: {

  publishDocsToGitHubPages = {

    "if" = utils.isMaster;
    permissions = {
      contents = "read";
      pages = "write";
      id-token = "write";
    };

    concurrency = {
      group = "pages";
      cancel-in-progress = false;
    };

    environment = {
      name = "github-pages";
      url = "\${{ steps.deployment.outputs.page_url }}";

    };

  };

  publishPackages = {

    permissions = {
      contents = "read";
      packages = "write";
    };

  };

}
