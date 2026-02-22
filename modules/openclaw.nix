{
  ...
}: {
  programs.openclaw = {
    enable = true;
    installApp = false;
    stateDir = "/opt/mediaserver/config/openclaw";
    workspaceDir = "/opt/mediaserver/openclaw/workspace";

    config = {
      auth.profiles."openai-codex:default" = {
        provider = "openai-codex";
        mode = "oauth";
      };

      agents.defaults = {
        model.primary = "openai-codex/gpt-5.3-codex";
        workspace = "/opt/mediaserver/openclaw/workspace";
      };

      agents.list = [
        {id = "main";}
        {
          id = "quick";
          name = "quick";
          workspace = "/opt/mediaserver/openclaw/workspace-quick";
          model = "google/gemini-2.5-flash";
          subagents.allowAgents = ["main"];
        }
      ];

      bindings = [
        {
          agentId = "quick";
          match.channel = "whatsapp";
        }
        {
          agentId = "quick";
          match.channel = "telegram";
        }
      ];

      commands = {
        native = "auto";
        nativeSkills = "auto";
      };

      channels.whatsapp = {
        dmPolicy = "allowlist";
        allowFrom = ["919988844215"];
        groupPolicy = "disabled";
        debounceMs = 0;
        mediaMaxMb = 50;
      };

      channels.telegram = {
        tokenFile = "/opt/mediaserver/config/openclaw/telegram-bot-token";
        allowFrom = [];
        groups."*".requireMention = true;
      };

      gateway = {
        port = 18789;
        mode = "local";
        bind = "lan";
        auth.mode = "token";
        trustedProxies = ["172.20.0.0/24"];
        tailscale = {
          mode = "off";
          resetOnExit = false;
        };
      };

      skills.install.nodeManager = "npm";
      plugins.entries.whatsapp.enabled = true;
    };
  };
}
