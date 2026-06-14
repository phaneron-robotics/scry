# Install scry-connect on the robot

`scry-connect` is the small server that runs on your robot and lets Scry
inspect and work with its ROS 2 graph — topics, nodes, services,
parameters, lifecycle, diagnostics, and more.

Pick whichever install method fits your setup. They all run the same
server; they differ only in how it's packaged and kept running.

## Requirements

- **ROS 2** installed and sourced — Humble, Jazzy, Kilted, Lyrical, or
  Rolling. Any middleware works (Fast-DDS, CycloneDDS, Connext, Zenoh) —
  `scry-connect` follows whatever your robot already uses.
- **Python 3.10+** (the Python that ships with ROS 2 is fine).
- **Network access** — the robot must be reachable from your phone.
- **~50 MB of disk.** No GPU, no root, no special hardware.

## Method 1 — One-line installer

The quickest way to a robot that's ready and stays running. The script
detects your ROS distro, installs the connect, sets it up to start
automatically as a background service, starts it, and prints a pairing
QR code.

```bash
curl -fsSL https://raw.githubusercontent.com/phaneron-robotics/scry/master/install.sh | bash
```

Re-running the command upgrades an existing install in place. To force a
particular method, set `SCRY_INSTALL_MODE` on the same line that pipes
the script into `bash`:

```bash
curl -fsSL https://raw.githubusercontent.com/phaneron-robotics/scry/master/install.sh | SCRY_INSTALL_MODE=docker bash    # always use Docker
curl -fsSL https://raw.githubusercontent.com/phaneron-robotics/scry/master/install.sh | SCRY_INSTALL_MODE=pip bash       # always use pip + background service
```

When it finishes, a QR code appears in the terminal — leave it visible
for the [pairing step](pair.md).

## Method 2 — pip install

Install directly from PyPI and run it. This is the simplest method if
you manage your own Python environment.

```bash
pip install scry-connect
scry-connect
```

The server starts on port **5339** and prints a pairing QR. From the
phone, scan the QR or enter the robot's IP address.

!!! tip "Keep it running after a reboot"
    Started this way, the connect runs until you stop it but won't come
    back automatically after a reboot. To run it as a background service
    that restarts on boot, use [Method 1](#method-1-one-line-installer),
    which sets that up for you, or add it to your own service manager.

## Method 3 — Docker

For containerized deployments, add the connect to your Compose stack:

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

| Image tag | Resolves to |
|---|---|
| `humble`, `jazzy`, `kilted`, `lyrical`, `rolling` | Latest connect on that ROS distro |
| `latest` | Same as `jazzy` |

Images are multi-architecture (`amd64` + `arm64`), so they run on x86
machines and on Jetson / Raspberry Pi 4+ alike.

## Verify the install

On the robot, check the connect is listening:

```bash
curl -s http://localhost:5339/health
```

A healthy server reports `"status":"ok"` along with the number of
available tools, the authentication mode, and the ROS distro it's
running against. If you see that, you're ready — continue to
[Pair the phone and robot](pair.md).

## Security at a glance

Out of the box, `scry-connect` runs in **open mode on your local
network**: it listens on your LAN but refuses connections from the
public internet, and it doesn't require a token. That's safe on a
trusted network because **every action Scry takes on the robot still has
to be approved with a tap on your phone** — reading is free, acting asks
first.

For tokens, mutual TLS, audit logging, and using Scry from outside the
robot's network, see [Connect from anywhere](../use/remote.md).

## Troubleshooting

??? failure "ImportError: No module named rclpy"
    ROS 2 isn't sourced in the shell that ran the install. Source your
    distro's setup file, for example:

    ```bash
    source /opt/ros/jazzy/setup.bash
    ```

    Then run the install again. The Docker method doesn't have this
    issue because the container already has ROS 2 sourced.

??? failure "Port 5339 already in use"
    Another connect is probably already running. Find and stop it:

    ```bash
    ss -tlnp | grep 5339
    systemctl --user stop scry-connect
    ```

??? failure "Phone can't reach the robot"
    Check that:

    - Phone and robot are on the **same network** (some routers isolate
      guest Wi-Fi from the main network).
    - The robot has a **private IP** (`192.168.x.x`, `10.x.x.x`, or
      `172.16–31.x.x`). Public IPs are refused by default.
    - The robot's firewall isn't blocking the port. On Ubuntu:
      `sudo ufw allow 5339/tcp`.

## Next

Your connect is running — time to [pair it with the phone](pair.md).
