{ jellarr, vars, ... }:
{
  imports = [ jellarr.nixosModules.default ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";

  services.jellyfin = {
    enable = true;
  };

  services.jellarr = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
    environmentFile = "${vars.mediaRoot}/.env";
    config = {
      version = 1;
      base_url = "http://127.0.0.1:8096";
      system = {
        enableMetrics = true;
      };
      library = {
        virtualFolders = [
          {
            name = "Movies";
            collectionType = "movies";
            libraryOptions = {
              pathInfos = [
                {
                  path = "${vars.hddMediaPath}/movies";
                }
              ];
            };
          }
          {
            name = "TV Shows";
            collectionType = "tvshows";
            libraryOptions = {
              pathInfos = [
                {
                  path = "${vars.hddMediaPath}/tv";
                }
              ];
            };
          }
          {
            name = "Music";
            collectionType = "music";
            libraryOptions = {
              pathInfos = [
                {
                  path = "${vars.hddMediaPath}/music";
                }
              ];
            };
          }
        ];
      };
      startup = {
        completeStartupWizard = true;
      };
    };
    bootstrap = {
      enable = false;
    };
  };
}
