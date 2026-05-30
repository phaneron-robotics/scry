#!/usr/bin/env bash
# scry-connect — one-line installer for a ROS 2 robot.
#
# Canonical hosted copy lives in the public scry repo so users on
# private networks can curl it without a GitHub token:
#   curl -fsSL https://raw.githubusercontent.com/phaneron-robotics/scry/master/install.sh | bash
#
# Keep this file in sync with scry/install.sh (this repo is the source
# of truth; copy the file over when you change it).
#
# Or, with explicit mode selection:
#   curl -fsSL .../install.sh | SCRY_INSTALL_MODE=docker bash
#   curl -fsSL .../install.sh | SCRY_INSTALL_MODE=pip bash
#
# Flags via env var:
#   SCRY_INSTALL_MODE  = auto | docker | pip       (default: auto)
#   ROS_DISTRO         = humble | jazzy | …        (auto-detected if unset)
#   SCRY_PORT          = 5339                       (default)
#   SCRY_AUTH_MODE     = open | token | mtls        (default: open)
#   SCRY_SYSTEMD       = 1 | 0                     (force-install / force-skip
#                                                    the unit; otherwise the
#                                                    script prompts the user
#                                                    when systemd is available
#                                                    and auto-skips when not)
#   SCRY_NO_SYSTEMD    = 1                          (legacy alias for SCRY_SYSTEMD=0)
#
# What it does:
#   1. Detects ROS distro from $ROS_DISTRO or /opt/ros/*/setup.bash.
#   2. Picks an install mode:
#        - docker → pulls ghcr.io/phaneron-robotics/scry-connect:$ROS_DISTRO,
#                   writes a systemd unit that runs the container with the
#                   right --network/--ipc/--pid flags, starts it.
#        - pip    → installs scry-connect into ~/.local/bin via pip,
#                   writes a systemd user unit that sources ROS and execs
#                   scry-connect, starts it.
#   3. Prints the pairing QR.
#
# Idempotent: re-running upgrades in place.

set -euo pipefail

INFO=$'\033[1;36m[scry]\033[0m'
WARN=$'\033[1;33m[warn]\033[0m'
FAIL=$'\033[1;31m[fail]\033[0m'
OK=$'\033[1;32m[ ok ]\033[0m'

# ─── helpers ────────────────────────────────────────────────────────────

info() { echo -e "$INFO $*"; }
warn() { echo -e "$WARN $*" >&2; }
fail() { echo -e "$FAIL $*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# Decide whether to write the systemd --user unit. Returns 0 (install
# it) or 1 (skip), printing a one-line rationale via info/warn.
#
# Precedence:
#   1. SCRY_NO_SYSTEMD=1      → skip, no prompt (legacy opt-out)
#   2. SCRY_SYSTEMD=1         → install, no prompt
#   3. SCRY_SYSTEMD=0         → skip, no prompt
#   4. systemctl missing OR
#      PID 1 isn't systemd    → skip automatically (chroot / WSL /
#                                Docker without systemd / macOS host)
#   5. /dev/tty unreadable    → skip (curl | bash in CI), tell the
#                                user how to opt in next time
#   6. Otherwise              → prompt "[Y/n]", default Y. Read from
#                                /dev/tty so it works under curl|bash.
want_systemd() {
    if [ "${SCRY_NO_SYSTEMD:-0}" = "1" ]; then
        info "Skipping systemd unit (SCRY_NO_SYSTEMD=1)."
        return 1
    fi
    case "${SCRY_SYSTEMD:-}" in
        1|yes|true) return 0 ;;
        0|no|false)
            info "Skipping systemd unit (SCRY_SYSTEMD=$SCRY_SYSTEMD)."
            return 1
            ;;
    esac
    if ! has systemctl; then
        info "systemctl not found — skipping systemd unit."
        return 1
    fi
    # PID 1 is the init binary. On real systemd hosts /proc/1/comm
    # contains "systemd"; in chroots / many containers / WSL it's
    # something else (bash, init, sh). Belt-and-braces: also check
    # that the user dbus socket exists.
    if [ -r /proc/1/comm ] && [ "$(cat /proc/1/comm 2>/dev/null)" != "systemd" ]; then
        info "PID 1 isn't systemd — skipping systemd unit."
        return 1
    fi
    # Open fd 3 onto /dev/tty for both reading and writing. If that
    # fails (CI, dockerized curl|bash with no tty attached, pipelines
    # under nohup, etc.), there's no human to ask — bail.
    if ! exec 3<>/dev/tty 2>/dev/null; then
        warn "No interactive terminal — skipping systemd unit. To install"
        warn "the unit non-interactively, re-run with SCRY_SYSTEMD=1."
        return 1
    fi
    local answer=""
    printf '%b Install a systemd --user unit so scry-connect starts on login? [Y/n]: ' "$INFO" >&3
    if ! read -r answer <&3; then
        # EOF on the tty also counts as "no human" — don't silently
        # default to yes just because read failed.
        exec 3<&-
        warn "Couldn't read from terminal — skipping systemd unit."
        warn "To install the unit non-interactively, re-run with SCRY_SYSTEMD=1."
        return 1
    fi
    exec 3<&-
    case "${answer,,}" in
        ""|y|yes) return 0 ;;
        *)
            info "Skipping systemd unit (user declined)."
            return 1
            ;;
    esac
}

# Detect the ROS distro the user has installed. Returns the distro name
# on stdout, or empty string if none found. Honours ROS_DISTRO env var.
detect_ros_distro() {
    if [ -n "${ROS_DISTRO:-}" ] && [ -d "/opt/ros/${ROS_DISTRO}" ]; then
        echo "$ROS_DISTRO"
        return
    fi
    # Pick the most recent distro alphabetically (rolling > lyrical > kilted
    # > jazzy > iron > humble) so a multi-install host gets the newer one.
    # Users can pin via $ROS_DISTRO.
    local newest=""
    local candidate
    for candidate in humble iron jazzy kilted lyrical rolling; do
        if [ -f "/opt/ros/${candidate}/setup.bash" ]; then
            newest="$candidate"
        fi
    done
    echo "$newest"
}

# Pick an install mode: docker if available unless the user pinned to pip.
choose_mode() {
    local requested="${SCRY_INSTALL_MODE:-auto}"
    case "$requested" in
        docker|pip) echo "$requested"; return ;;
        auto)
            if has docker; then echo "docker"; else echo "pip"; fi
            ;;
        *)
            fail "unknown SCRY_INSTALL_MODE=$requested (expected: auto|docker|pip)"
            ;;
    esac
}

# Print the LAN IP for the pairing message.
host_ip() {
    hostname -I 2>/dev/null | awk '{print $1}' || hostname
}

# ─── mode implementations ───────────────────────────────────────────────

install_docker() {
    local distro="$1"
    local port="${SCRY_PORT:-5339}"
    local image="ghcr.io/phaneron-robotics/scry-connect:${distro}"

    info "Mode: docker (image: $image)"

    if ! docker info >/dev/null 2>&1; then
        fail "docker daemon is not reachable. Start it (\`sudo systemctl start docker\`) or run with SCRY_INSTALL_MODE=pip."
    fi

    info "Pulling image (this may take a couple of minutes on first run)…"
    docker pull "$image"

    if ! want_systemd; then
        info "Start manually with:"
        echo "    docker run -d --restart=unless-stopped --network=host --ipc=host --pid=host \\"
        echo "      -e ROS_DOMAIN_ID=\$ROS_DOMAIN_ID --name scry-connect $image"
        return
    fi

    local unit_dir="${HOME}/.config/systemd/user"
    mkdir -p "$unit_dir"
    local unit_path="${unit_dir}/scry-connect.service"

    cat > "$unit_path" <<EOF
[Unit]
Description=Scry Connect (Docker sidecar)
After=docker.service network-online.target
Requires=docker.service

[Service]
Type=simple
ExecStartPre=-/usr/bin/docker rm -f scry-connect
ExecStart=/usr/bin/docker run --rm --name scry-connect \\
    --network=host --ipc=host --pid=host \\
    -e ROS_DOMAIN_ID=\${ROS_DOMAIN_ID:-0} \\
    -e SCRY_PORT=${port} \\
    -e SCRY_AUTH_MODE=\${SCRY_AUTH_MODE:-${SCRY_AUTH_MODE:-open}} \\
    -e SCRY_TOKEN=\${SCRY_TOKEN:-} \\
    -v scry_config:/home/scry/.config/scry \\
    -v scry_audit:/var/log/scry \\
    ${image}
ExecStop=/usr/bin/docker stop scry-connect
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    info "Installed systemd user unit: $unit_path"

    if has systemctl; then
        systemctl --user daemon-reload || true
        systemctl --user enable --now scry-connect.service || \
            warn "systemctl --user enable failed (loginctl enable-linger may be required for headless boot)"
    fi

    # Give the container a moment to bind, then print the QR.
    sleep 3
    info "Pairing QR (scan with the Scry Android app):"
    docker exec scry-connect scry-connect --print-qr || \
        warn "Container not ready yet — try \`docker exec scry-connect scry-connect --print-qr\` shortly."
}

install_pip() {
    local distro="$1"
    local port="${SCRY_PORT:-5339}"

    info "Mode: pip (bare-metal, systemd user unit)"

    if ! has python3; then
        fail "python3 not found. Install it first (sudo apt install python3 python3-venv)."
    fi

    local pyver
    pyver=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    info "python3 ${pyver} detected"

    # Where the scry-connect binary will live. The systemd unit + the
    # post-install "run this" hints both expect this path.
    local bin_path

    # Decide between an existing active venv vs. a managed one we create.
    #
    # We never touch the system Python directly. On Ubuntu 24.04+
    # (jazzy / kilted / rolling) and 26.04 (lyrical) the system Python
    # is PEP 668 externally-managed; on every distro a venv is the
    # right tool for "install a Python app." A managed venv also keeps
    # scry-connect's deps isolated from anything apt ships, so OS
    # upgrades don't drag the install with them.
    #
    # Critical detail: ``--system-site-packages`` is required so the
    # venv can still ``import rclpy`` from /opt/ros/<distro>/. Without
    # it the venv is hermetic and scry-connect fails on first import.
    local venv
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        info "Active venv detected at \$VIRTUAL_ENV — installing into it: $VIRTUAL_ENV"
        venv="$VIRTUAL_ENV"
    else
        venv="${HOME}/.local/share/scry-connect/venv"
        if [ ! -x "${venv}/bin/python" ]; then
            info "Creating dedicated venv at ${venv} (with --system-site-packages for rclpy)…"
            mkdir -p "$(dirname "$venv")"
            if ! python3 -m venv --system-site-packages "$venv" 2>/tmp/scry-venv.err; then
                if grep -q "ensurepip\|venv" /tmp/scry-venv.err 2>/dev/null; then
                    fail "python3-venv is not installed. Run: sudo apt install python3-venv"
                fi
                cat /tmp/scry-venv.err >&2
                fail "Failed to create venv at ${venv}."
            fi
        else
            info "Reusing existing venv at ${venv}"
        fi
    fi

    info "Installing scry-connect from PyPI into the venv…"
    "${venv}/bin/pip" install --upgrade scry-connect

    bin_path="${venv}/bin/scry-connect"
    if [ ! -x "$bin_path" ]; then
        fail "Install completed but ${bin_path} is missing. Aborting."
    fi

    # Expose scry-connect on $PATH via a symlink in ~/.local/bin.
    mkdir -p "${HOME}/.local/bin"
    ln -sf "$bin_path" "${HOME}/.local/bin/scry-connect"
    info "Symlinked ${HOME}/.local/bin/scry-connect -> ${bin_path}"

    # Make sure ~/.local/bin is on PATH for current shell hints.
    if ! echo ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
        warn "$HOME/.local/bin is not on \$PATH. Add to your shell rc:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    if ! want_systemd; then
        info "Start manually with:"
        echo "    source /opt/ros/${distro}/setup.bash"
        echo "    ${bin_path} --port ${port}"
        return
    fi

    local unit_dir="${HOME}/.config/systemd/user"
    mkdir -p "$unit_dir"
    local unit_path="${unit_dir}/scry-connect.service"

    # Invoke the venv binary directly. That way the unit keeps working
    # even if the user later removes the ~/.local/bin/scry-connect
    # symlink (or if VIRTUAL_ENV pointed at a non-canonical path).
    cat > "$unit_path" <<EOF
[Unit]
Description=Scry Connect (MCP server for ROS 2)
After=network-online.target

[Service]
Type=simple
Environment="ROS_DISTRO=${distro}"
Environment="SCRY_PORT=${port}"
ExecStart=/bin/bash -lc 'source /opt/ros/\${ROS_DISTRO}/setup.bash && exec ${bin_path}'
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF
    info "Installed systemd user unit: $unit_path"

    if has systemctl; then
        systemctl --user daemon-reload || true
        systemctl --user enable --now scry-connect.service || \
            warn "systemctl --user enable failed (try \`loginctl enable-linger \$USER\` for headless boot)"
    fi

    sleep 2
    info "Pairing QR (scan with the Scry Android app):"
    "$bin_path" --print-qr || \
        warn "scry-connect not started yet — run \`${bin_path} --print-qr\` after sourcing your ROS setup.bash."
}

# ─── main ───────────────────────────────────────────────────────────────

info "scry-connect installer starting"

distro="$(detect_ros_distro)"
if [ -z "$distro" ]; then
    fail "No ROS 2 install detected under /opt/ros/. Install ROS 2 first:
       https://docs.ros.org/en/jazzy/Installation.html
       Then re-run this installer."
fi
info "ROS distro: ${distro}"

mode="$(choose_mode)"

case "$mode" in
    docker) install_docker "$distro" ;;
    pip)    install_pip "$distro" ;;
esac

ip="$(host_ip)"
port="${SCRY_PORT:-5339}"

echo
echo -e "$OK Install complete."
echo
echo "    Open the Scry Android app → Add robot → Scan QR"
echo "    or paste:  ${ip}:${port}"
echo
echo "Logs:"
case "$mode" in
    docker) echo "    docker logs -f scry-connect" ;;
    pip)    echo "    journalctl --user -fu scry-connect" ;;
esac
echo
