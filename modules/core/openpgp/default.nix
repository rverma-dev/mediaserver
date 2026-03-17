{pkgs, config, lib, ...}: let
  cfg = config.services.openpgp;
in {
  options.services.openpgp = {
    enable = lib.mkEnableOption "OpenPGP (GnuPG) service";
    
    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.gnupg";
      description = "GnuPG home directory";
    };
    
    keyServer = lib.mkOption {
      type = lib.types.str;
      default = "hkps://keys.openpgp.org";
      description = "Default keyserver for key operations";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [gnupg];
    
    home.sessionVariables = {
      GNUPGHOME = cfg.homeDir;
    };
    
    home.file.".gnupg/gpg.conf".text = ''
      # Use SHA-512 for digest operations
      digest-algo SHA512
      
      # Use AES-256 for symmetric encryption
      personal-cipher-preferences AES256 AES192 AES CAST5
      
      # Use stronger compression
      compress-algo ZLIB BZIP2 ZIP Uncompressed
      
      # Keyserver settings
      keyserver ${cfg.keyServer}
      keyserver-options auto-key-retrieve
      
      # Trust model
      trust-model tofu+pgp
      
      # Charset
      charset utf-8
      
      # Display options
      no-greeting
      no-emit-version
      list-options show-uid-validity
      verify-options show-uid-validity
      
      # Security settings
      require-cross-certification
      no-similarity-check
      use-agent
    '';
    
    home.file.".gnupg/gpg-agent.conf".text = ''
      # Enable SSH support
      enable-ssh-support
      
      # Default cache TTL
      default-cache-ttl 3600
      max-cache-ttl 7200
      
      # Pinentry program
      pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses
      
      # Keep TTY
      allow-emacs-pinentry
      allow-loopback-pinentry
    '';
    
    systemd.user.services.gpg-agent = {
      Unit = {
        Description = "GnuPG cryptographic agent and passphrase cache";
        Documentation = "man:gpg-agent(1)";
      };
      
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.gnupg}/bin/gpg-agent --daemon --use-standard-socket";
        Restart = "on-failure";
      };
      
      Install.WantedBy = ["default.target"];
    };
  };
}
