{
  lib,
  pkgs,
  vars,
  ...
}: let
  syncJellyfinKey = pkgs.writeShellScript "sync-seerr-jellyfin-key" ''
    set -euo pipefail
    settings="${vars.mediaRoot}/config/seerr/settings.json"
    env_file="${vars.mediaRoot}/.env"

    [[ -f "$settings" && -f "$env_file" ]] || exit 0

    set -a
    source "$env_file"
    set +a
    [[ -n "''${JELLYFIN_API_KEY:-}" ]] || exit 0

    ${pkgs.python3}/bin/python - "$settings" <<'PY'
    import json
    import os
    import sys
    import tempfile
    from pathlib import Path

    path = Path(sys.argv[1])
    data = json.loads(path.read_text())
    jellyfin = data.setdefault("jellyfin", {})
    key = os.environ["JELLYFIN_API_KEY"]
    if jellyfin.get("apiKey") == key:
        raise SystemExit(0)

    jellyfin["apiKey"] = key
    fd, temporary = tempfile.mkstemp(prefix=f"{path.name}.", dir=path.parent)
    os.close(fd)
    os.chmod(temporary, path.stat().st_mode)
    Path(temporary).write_text(json.dumps(data, indent=2) + "\n")
    os.replace(temporary, path)
    PY
  '';
in {
  systemd.user.services.seerr = {
    Unit = {
      Description = "Seerr - Media request manager";
      After = ["network-online.target" "wireproxy.service" "sonarr.service" "radarr.service" "prowlarr.service"];
      Requires = ["wireproxy.service" "prowlarr.service"];
    };
    Service = {
      ExecStartPre = "${syncJellyfinKey}";
      ExecStart = "${vars.pkgs.seerr}/bin/seerr";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "CONFIG_DIRECTORY=${vars.mediaRoot}/config/seerr"
        "LOG_LEVEL=warn"
        "TZ=${vars.tz}"
        "PORT=5055"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
