# scry-connect as a Docker sidecar

A drop-in [`docker-compose.yml`](docker-compose.yml) that runs
`scry-connect` in a container next to your robot's ROS 2 stack. One file
covers every supported distro — the image tag is set by `ROS_DISTRO`.

## Run it

```bash
# Pick your ROS distro: humble · jazzy · kilted · lyrical · rolling
ROS_DISTRO=jazzy docker compose up -d

# Print the pairing QR to scan with the Scry app
docker compose exec scry-connect scry-connect --print-qr
```

Prefer a file? Copy [`.env.example`](.env.example) to `.env`, edit it,
then just `docker compose up -d`.

## Verify

```bash
curl -s http://localhost:5339/health
```

A healthy server reports `"status":"ok"`.

## Notes

- **Host networking** (`network_mode: host`) lets the connect join your
  robot's existing DDS bus directly. `ipc: host` and `pid: host` enable
  shared-memory DDS and the app's process view; drop `pid: host` if you
  don't need it.
- **Images are multi-arch** (amd64 + arm64) — same file on x86, Jetson,
  and Raspberry Pi 4+.
- **GPU (optional):** the connect itself needs no GPU, but uncomment the
  GPU blocks in `docker-compose.yml` if the container runs CUDA-backed
  ROS nodes or sits on a Jetson. Requires the
  [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
  on the host.
- **Upgrades:** `docker compose pull && docker compose up -d`. Pinning to
  a release (e.g. `:1.2.1-jazzy`) instead of a floating distro tag gives
  you reproducible deployments.
- **Auth and remote access:** the connect runs open on the LAN by
  default. For tokens, mutual TLS, and use from outside the robot's
  network, see the [remote-access docs](https://phaneron-robotics.github.io/scry/use/remote/).

Full install guide:
<https://phaneron-robotics.github.io/scry/get-started/install-connect/>
