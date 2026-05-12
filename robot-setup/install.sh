#!/usr/bin/env bash
# Scry Connect — one-line installer for your robot.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/phaneron/scry/main/robot-setup/install.sh | bash
#
set -euo pipefail

INFO="\033[1;36m[scry]\033[0m"
WARN="\033[1;33m[warn]\033[0m"
FAIL="\033[1;31m[fail]\033[0m"

echo -e "$INFO Installing scry-connect..."

if ! command -v python3 >/dev/null 2>&1; then
    echo -e "$FAIL python3 not found. Install Python 3.10+ first."
    exit 1
fi

PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo -e "$INFO Python $PY_VERSION detected"

if [ -z "${ROS_DISTRO:-}" ]; then
    echo -e "$WARN ROS_DISTRO not set — did you source /opt/ros/<distro>/setup.bash?"
    echo -e "$WARN The connect will install but topic tools will not work."
fi

if ! command -v pip3 >/dev/null 2>&1; then
    echo -e "$FAIL pip3 not found. Install python3-pip first."
    exit 1
fi

echo -e "$INFO Installing scry-connect via pip..."
pip3 install --user --upgrade scry-connect

HOST=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
PORT="${SCRY_PORT:-5339}"

echo ""
echo -e "$INFO Install complete."
echo ""
echo -e "$INFO To start the connect:"
echo "    source /opt/ros/\$ROS_DISTRO/setup.bash"
echo "    scry-connect --port $PORT"
echo ""
echo -e "$INFO In the Scry app, add a robot with:"
echo "    Host: $HOST"
echo "    Port: $PORT"
echo ""
