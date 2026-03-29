{
  description = "Pi 5 Media Server — Nix-managed services (binary-only)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # camera-mock.url = "github:rverma-dev/v1-camera-mock";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    vars = {
      user = "pi";
      host = "pi";
      puid = "1000";
      pgid = "1000";
      tz = "Asia/Kolkata";
      lanIp = "192.168.68.60";
      mediaRoot = "/home/pi/mediaserver";
      hddMountPath = "/mnt/hdd";
      hddDownloadsPath = "/mnt/hdd/downloads";
      hddMediaPath = "/mnt/hdd/media";
      hddImmichLibrary = "/mnt/hdd/immich/library";
      cameraMock = {
        enable = false;
        environmentFile = "/home/pi/mediaserver/.env";
      };
    };

    supportedSystems = ["aarch64-linux" "x86_64-linux"];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    packages = forAllSystems (system: let
      pkgs = mkPkgs system;
    in
      import ./pkgs {inherit pkgs;});

    devShells = forAllSystems (system: let
      pkgs = mkPkgs system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [nil nixfmt-rfc-style];
      };
    });

    homeConfigurations."pi" = let
      system = "aarch64-linux";
      pkgs = mkPkgs system;
      mediaPkgs = import ./pkgs {inherit pkgs;};
    in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./hosts/pi
        ];
        extraSpecialArgs = {
          vars = vars // {pkgs = mediaPkgs;};
        };
      };
  };
}
