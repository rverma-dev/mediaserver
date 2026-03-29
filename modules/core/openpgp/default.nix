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

    generateKey = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to generate a new GPG key";
    };

    keyConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {
        name = "Rohit Verma";
        email = "rverma-dev@users.noreply.github.com";
        expireDate = "1y";
      };
      description = "GPG key configuration";
    };

    gitSign = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Configure Git to use GPG signing";
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

    # GPG key generation script
    home.file.".local/bin/generate-gpg-key" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        GNUPGHOME="${cfg.homeDir}"
        export GNUPGHOME

        # Check if key already exists
        if gpg --list-secret-keys --keyid-format LONG "${cfg.keyConfig.email}" 2>/dev/null | grep -q "sec"; then
          echo "GPG key already exists for ${cfg.keyConfig.email}"
          exit 0
        fi

        # Generate key batch
        cat > /tmp/gpg-keygen <<EOF
          %echo Generating GPG key
          Key-Type: RSA
          Key-Length: 4096
          Subkey-Type: RSA
          Subkey-Length: 4096
          Name-Real: ${cfg.keyConfig.name}
          Name-Email: ${cfg.keyConfig.email}
          Expire-Date: ${cfg.keyConfig.expireDate}
          %no-protection
          %commit
          %echo done
        EOF

        gpg --batch --full-generate-key /tmp/gpg-keygen
        rm -f /tmp/gpg-keygen

        echo "GPG key generated successfully!"
        gpg --list-secret-keys --keyid-format LONG "${cfg.keyConfig.email}"
      '';
      executable = true;
    };

    # Git GPG configuration
    programs.git = lib.mkIf cfg.gitSign {
      signing = {
        signByDefault = true;
        key = null; # Will be set after key generation
      };
      settings = {
        gpg.program = "${pkgs.gnupg}/bin/gpg";
        commit.gpgsign = true;
        tag.gpgsign = true;
      };
    };

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
