# Alloy Docker/cAdvisor Troubleshooting

## Common issues

### 1. mount-id: no such file or directory (Docker 29+)

**Error:**
```
Failed to create existing container: ... failed to identify the read-write layer ID for container "..."
open /var/lib/docker/image/overlayfs/layerdb/mounts/<id>/mount-id: no such file or directory
```

**Cause:** Docker 29+ uses containerd-snapshotter by default. The image store layout changed; cAdvisor (and Alloy's embedded fork) still expects the old overlayfs layerdb structure.

**Fix:** Disable containerd-snapshotter in Docker daemon so it uses the legacy image store.

Edit `/etc/docker/daemon.json` and add the `features` block (merge with existing keys if the file already exists):
```json
{
  "features": {
    "cdi": true,
    "containerd-snapshotter": false
  }
}
```

Then restart Docker:
```bash
sudo systemctl restart docker
```

**Note:** If you have existing containers, you may need to recreate them after this change. Alloy's cAdvisor fork will eventually support Docker 29 natively (see [grafana/alloy#5021](https://github.com/grafana/alloy/issues/5021)).

### 2. Docker socket permissions (most likely)

cAdvisor needs access to the Docker socket and `/var/lib/docker/`. When Alloy runs as a systemd service, the `alloy` user often lacks access.

**Fix:**
```bash
sudo usermod -aG docker alloy
sudo systemctl restart alloy
```

If the Alloy service uses a different user (e.g. `alloyd`), use that instead:
```bash
id alloy alloyd 2>/dev/null || ps -o user= -p $(pgrep -f alloy | head -1)
```

### 3. Drop rule dropping all metrics

This rule can drop metrics:
```alloy
rule {
    source_labels = ["name"]
    regex         = ""
    action        = "drop"
}
```
An empty `regex = ""` can match unexpectedly. **Remove this rule** or use a specific pattern (e.g. `regex = "unwanted_container"`).

### 4. Explicit docker_host

Add `docker_host` for clarity:
```alloy
prometheus.exporter.cadvisor "integrations_cadvisor" {
    docker_host   = "unix:///var/run/docker.sock"
    docker_only   = true
    storage_duration = "5m"
}
```

### 5. Verify cAdvisor targets

Check that cAdvisor exposes targets:
```bash
curl -s http://localhost:12345/api/v0/component/prometheus.exporter.cadvisor.integrations_cadvisor/status | jq
```

Or open Alloy UI: `http://<pi-ip>:12345` and inspect component health.

### 6. Verify scrape

```bash
curl -s "http://localhost:12345/api/v0/component/prometheus.scrape.integrations_cadvisor/targets" | jq
```

## Quick fix script

Run after Alloy is installed:
```bash
sudo usermod -aG docker alloy 2>/dev/null || sudo usermod -aG docker alloyd
sudo systemctl restart alloy
```
