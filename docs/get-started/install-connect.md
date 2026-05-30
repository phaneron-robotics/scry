# Install scry-connect on the robot

`scry-connect` is the Python MCP server that runs on your robot. It
exposes ROS 2 topics, nodes, services, actions, parameters, lifecycle,
diagnostics, and 100+ other tools to the AI agent on your phone.

Three install paths, in order of recommendation. All three install the
same `scry-connect` from PyPI — they just package it differently.

## Requirements

- **ROS 2** installed and sourced — Humble, Iron, Jazzy, Kilted,
  Lyrical, or Rolling. Any DDS (Fast-DDS, CycloneDDS, Connext, Zenoh)
  works since scry-connect uses `rclpy` (RMW-agnostic). Pre-built
  Docker images are published for Humble, Jazzy, and Rolling; the other
  distros run via the pip path.
- **Python 3.10+** (ROS 2 ships its own python; that's fine).
- **WiFi** — the robot must be reachable from your phone on the LAN.
- **~50 MB disk** for the install. No GPU, no root, no special hardware.

## Option A — One-line installer (recommended)

Works on bare-metal Linux and inside Docker. The script auto-detects
your ROS distro, picks Docker if available else pip, writes a
`systemd --user` unit, starts the service, and prints a pairing QR.

```bash
curl -fsSL https://raw.githubusercontent.com/phaneron-robotics/scry/master/install.sh | bash
```

Re-running upgrades in place.

**Force a specific install mode:**

```bash
SCRY_INSTALL_MODE=docker bash    # always Docker
SCRY_INSTALL_MODE=pip bash       # always pip + systemd
```

When the script finishes you'll see a QR code in the terminal. Leave it
visible — you'll scan it from the phone in the next step.

## Option B — Docker sidecar (for compose-based deployments)

Drop into your existing `docker-compose.yml`:

```yaml
services:
  scry-connect:
    image: ghcr.io/phaneron-robotics/scry-connect:${ROS_DISTRO:-jazzy}
    network_mode: host
    ipc: host
    pid: host
    restart: unless-stopped
    environment:
      - ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
    volumes:
      - scry_config:/home/scry/.config/scry
      - scry_audit:/var/log/scry

volumes:
  scry_config:
  scry_audit:
```

A turnkey reference compose with every tunable surfaced lives at
[`docker/docker-compose.yml`](https://github.com/phaneron-robotics/scry-connect/blob/master/docker/docker-compose.yml)
in the connect repo.

| Image tag | Resolves to |
|---|---|
| `humble`, `jazzy`, `kilted`, `lyrical`, `rolling` | Latest scry-connect on that ROS distro |
| `0.1.1-jazzy` (etc.) | Pinned scry-connect version |
| `latest` | `jazzy` |

Multi-arch: `linux/amd64` + `linux/arm64`. Works on x86 dev boxes and
Jetson / Raspberry Pi 4+ alike.

## Option C — pip install (for hacky one-off testing)

```bash
pip install scry-connect && scry-connect
```

The connect starts on port **5339** in **open mode on RFC1918 / loopback**
(rejects callers from public IPs by default). Open Scry on your phone
and either scan the QR the connect prints, or enter the robot's IP
address manually.

This path **doesn't survive reboot.** Use it for quick testing only.
For anything persistent, pick Option A or B.

## Verify the install

On the robot, check the connect is listening:

```bash
curl -s http://localhost:5339/health
# → {"status":"ok","service":"scry-connect","hostname":"robot",
#    "tools":103,"auth_mode":"open","auth_required":false,
#    "deadman_required":false,"domain_id":0,"ros_distro":"jazzy"}
```

If you see the JSON above, you're done. Move on to
[Pair the phone and robot](pair.md).

## Security model

scry-connect ships in **open mode** by default — LAN-only, no token,
matching `rosbridge` / `foxglove_bridge`. Concretely, the default
posture:

- **Listens on `0.0.0.0:5339`** but **rejects callers whose source IP
  isn't private (RFC1918 / loopback)**. This blocks accidental
  internet exposure if you forget a firewall rule. Pass
  `--public-internet` to lift that check (think twice — anyone who can
  reach the port can drive the robot).
- **Does not require a token, even for write tools.** In open mode the
  write gate lives on the phone: the Android app shows a
  `ConfirmationCard` before dispatching any write, and the connect's
  `safety` envelope clamps velocity/trajectory commands. LAN reach is
  the trust boundary.

Tighten the posture with opt-in flags:

```bash
scry-connect --token         # token mode: every request needs the paired token.
                             # Auto-generates + prints a QR-pairable token.
                             # In token (or mTLS) mode the connect also enforces a
                             # one-shot X-Scry-Confirm nonce on every write tool.

scry-connect --mtls          # require TLS client certificates. Terminate TLS at
                             # your reverse proxy (nginx) or uvicorn
                             # (--ssl-cert-reqs=2); the connect enforces presence.

scry-connect --audit-log /var/log/scry/audit.jsonl   # append a JSONL entry
                             # (caller, tool, approval state) for every write tool.

scry-connect --require-deadman   # reject writes unless /scry/enable was published
                                 # True within the last second (deadman switch).
```

See the [scry-connect README](https://github.com/phaneron-robotics/scry-connect#security)
for the full security envelope.

## Troubleshooting

??? failure "ImportError: No module named rclpy"
    ROS 2 isn't sourced in the shell that ran the install. Source
    `setup.bash` from your distro:

    ```bash
    source /opt/ros/jazzy/setup.bash
    ```

    Then re-run the install. The Docker path doesn't have this issue
    because the container ships with ROS 2 already sourced.

??? failure "Port 5339 already in use"
    Another scry-connect is probably already running. Find and stop
    it:

    ```bash
    ss -tlnp | grep 5339
    systemctl --user stop scry-connect
    ```

    The systemd path runs as a `--user` service, not system-wide.

??? failure "Phone can't reach the robot"
    Triple-check:

    - Phone and robot on the **same WiFi network** (some routers
      isolate guest WiFi from main WiFi)
    - Robot's WiFi has a **private IP** (`192.168.x.x`, `10.x.x.x`,
      or `172.16-31.x.x`). Public IPs are rejected by default.
    - The robot's firewall isn't dropping `:5339`. On Ubuntu:
      `sudo ufw allow 5339/tcp`.

## Next

You have a running connect. Time to [pair it with the phone](pair.md).
