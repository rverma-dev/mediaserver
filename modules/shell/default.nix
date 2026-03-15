{
  lib,
  pkgs,
  vars,
  ...
}: {
  home.packages = with pkgs; [
    eza
    bat
    btop
    fd
    zoxide
    delta
    lazygit
    gh
    yt-dlp
    ffmpeg
  ];

  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };

  home.shellAliases = {
    ls = "${pkgs.eza}/bin/eza --icons=always --color=always";
    l = "ls -l";
    ll = "ls -la";
    la = "ls -la";
    lt = "ls --tree";
    cat = "${pkgs.bat}/bin/bat";
    tree = "${pkgs.eza}/bin/eza --tree";
    grep = "grep --color=auto";
    lg = "lazygit";

    ".." = "cd ..";
    "..." = "cd ../..";

    ms = "cd ${vars.mediaRoot}";
    msl = "journalctl --user -f";
    mss = "systemctl --user status caddy sonarr radarr prowlarr bazarr jellyfin seerr qbittorrent wireproxy immich immich-db immich-redis";
    msr = "systemctl --user restart";
    mslog = "journalctl --user -u";

    dfh = "df -h / /dev/nvme0n1p2 2>/dev/null | uniq";
    memf = "free -h";
    temps = "vcgencmd measure_temp 2>/dev/null || echo 'vcgencmd not available'";
    ports = "ss -tlnp";

    warp-status = "curl -s --socks5 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace | grep warp";
    warp-ip = "curl -s --socks5 127.0.0.1:1080 https://ifconfig.me";

    immich = "cd ${vars.mediaRoot} && systemctl --user status immich immich-db immich-redis";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      dark = true;
      color-only = true;
      paging = "never";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Rohit Verma";
        email = "rverma-dev@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      url."git@github.com:".insteadOf = "https://github.com/";
      core.excludesFile = "~/.config/git/gitignore";
    };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      inline_height = 25;
      invert = true;
      search_mode = "skim";
      secrets_filter = true;
      style = "compact";
    };
    flags = ["--disable-up-arrow"];
  };

  programs.lazygit = {
    enable = true;
    settings.git.paging = {
      colorArg = "always";
      pager = "delta --color-only --dark --paging=never";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--bind '?:toggle-preview'"
      "--bind 'ctrl-a:select-all'"
      "--color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'"
      "--height=40%"
      "--info=inline"
      "--layout=reverse"
      "--multi"
      "--preview '([[ -f {} ]] && (${pkgs.bat}/bin/bat --color=always --style=numbers,changes {})) || ([[ -d {} ]] && (${pkgs.eza}/bin/eza --tree --color=always {})) || echo {}'"
      "--preview-window=:hidden"
      "--prompt='~ ' --pointer='▶' --marker='✓'"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      italic-text = "always";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[λ=>](bold green)";
        error_symbol = "[❯](bold red)";
      };
      directory.truncation_length = 4;
      git_branch.symbol = " ";
      nix_shell = {
        symbol = " ";
        format = "via [$symbol$state( \\($name\\))]($style) ";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 20000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
    };

    initContent = ''
      # Better directory navigation
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

      # History dedup
      setopt HIST_REDUCE_BLANKS HIST_FIND_NO_DUPS

      # Cursor Agent CLI (used by headless Cursor and OpenClaw cursor-bridge)
      if [[ -f ${vars.mediaRoot}/.env ]] && [[ -z "$CURSOR_API_KEY" ]]; then
        export CURSOR_API_KEY=$(grep -m1 '^CURSOR_API_KEY=' ${vars.mediaRoot}/.env | cut -d= -f2)
      fi

      # Load local overrides if present
      [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
    '';
  };

  # Keep bash as a minimal fallback (non-interactive logins, scripts)
  programs.bash = {
    enable = true;
    initExtra = ''
      [[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
    '';
  };

  # Set zsh as default login shell
  home.activation.setDefaultShell = lib.hm.dag.entryAfter ["writeBoundary"] ''
    zsh_path="${pkgs.zsh}/bin/zsh"
    current_shell=$(/usr/bin/getent passwd pi | cut -d: -f7)
    if [[ "$current_shell" != "$zsh_path" ]]; then
      if ! grep -qF "$zsh_path" /etc/shells; then
        echo "$zsh_path" | /usr/bin/sudo /usr/bin/tee -a /etc/shells > /dev/null
      fi
      /usr/bin/sudo /usr/bin/chsh -s "$zsh_path" pi
      echo "Default shell set to zsh"
    fi
  '';
}
