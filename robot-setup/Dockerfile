# scry-connect sidecar image — what robots actually deploy.
#
# Lightweight (~1.4 GB): ROS 2 ros-base + Python runtime + scry-connect
# pip-installed from PyPI. No desktop tools, no Gazebo, no Nav2 — those
# live in the simulation image, not on the robot.
#
# Defaults to the LATEST_LTS_DISTRO (jazzy). Override at build time with:
#   docker build --build-arg ROS_DISTRO=humble --build-arg SCRY_CONNECT_VERSION=0.1.0 .
#
# The version pin matches the release-workflow's GHCR tag scheme, so the
# resulting image is functionally equivalent to:
#   ghcr.io/phaneron-robotics/scry-connect:${SCRY_CONNECT_VERSION}-${ROS_DISTRO}
# (once that registry is set to public — for now PyPI is the canonical
# source of truth and this Dockerfile is the build-locally fallback).

ARG ROS_DISTRO=jazzy
FROM ros:${ROS_DISTRO}-ros-base
ARG ROS_DISTRO
ARG SCRY_CONNECT_VERSION=0.1.0

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    ROS_DISTRO=${ROS_DISTRO}

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# pip install scry-connect from PyPI. ``--break-system-packages`` is
# required on Ubuntu 24.04 (Noble) where the base Python is marked
# externally-managed (PEP 668); on older bases it's a no-op via the
# ``2>/dev/null || pip install`` fallback below.
RUN python3 -m pip install --no-cache-dir --break-system-packages \
        "scry-connect==${SCRY_CONNECT_VERSION}" 2>/dev/null \
 || python3 -m pip install --no-cache-dir \
        "scry-connect==${SCRY_CONNECT_VERSION}"

EXPOSE 5339

# Source the ROS distro on every shell invocation so ``rclpy`` and the
# message definitions are importable. ``exec scry-connect "$@"`` makes
# the container respond to CLI args / overrides cleanly:
#   docker run scry-connect:latest --port 5340
#   docker run scry-connect:latest pair
ENTRYPOINT ["/bin/bash", "-c", "source /opt/ros/${ROS_DISTRO}/setup.bash && exec scry-connect \"$@\"", "--"]
CMD ["--host", "0.0.0.0", "--port", "5339"]
