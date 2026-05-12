# Scry

> Your ROS 2 robot in your pocket — AI-first debugging from Android,
> with an MCP server on the robot.

Scry is an open-source toolkit that connects an Android phone to any
ROS 2 robot over WiFi and uses an AI agent (Claude, GPT, Gemini, or
local Ollama) to diagnose, inspect, and control the robot through
natural language.

This is the **umbrella repository** — it contains the architecture
overview, robot install scripts, and `docker-compose` files for
spinning up the whole stack. The actual code lives in sibling repos:

| Repository | What it is |
|------------|------------|
| **[scry-connect](https://github.com/phaneron-robotics/scry-connect)** | Python MCP server. Runs on the robot. `pip install scry-connect`. |
| **[scry-android](https://github.com/phaneron-robotics/scry-android)** | Android app. Kotlin / Jetpack Compose. Play Store. |
| **[scry-ios](https://github.com/phaneron-robotics/scry-ios)** | iOS app. Swift / SwiftUI. App Store. *(planned)* |
| **[scry-docs](https://github.com/phaneron-robotics/scry-docs)** | Full documentation site. Hosted at <https://phaneron-robotics.github.io/scry-docs/>. |
| **[scry-brand](https://github.com/phaneron-robotics/scry-brand)** | Logos, icons, color tokens. |

## Architecture

```
                       ┌─────────────────────────────┐
                       │      Android phone          │
                       │                             │
                       │   ┌─────────────────────┐   │
                       │   │   AI provider       │   │
                       │   │   (Claude / GPT /   │   │
                       │   │    Gemini / Ollama) │   │
                       │   └─────────┬───────────┘   │
                       │             │ tool calls    │
                       │             ▼               │
                       │   ┌─────────────────────┐   │
                       │   │   AiProxyLoop       │   │
                       │   │   (MCP routing,     │   │
                       │   │    user approval,   │   │
                       │   │    rich rendering)  │   │
                       │   └─────────┬───────────┘   │
                       └─────────────┼───────────────┘
                                     │ HTTPS + MCP
                                     │ JSON-RPC + SSE
                                     ▼
                       ┌─────────────────────────────┐
                       │       Robot (any Linux)     │
                       │                             │
                       │   ┌─────────────────────┐   │
                       │   │   scry-connect      │   │
                       │   │   (Python MCP)      │   │
                       │   └─────────┬───────────┘   │
                       │             │ rclpy         │
                       │             ▼               │
                       │   ┌─────────────────────┐   │
                       │   │     ROS 2 graph     │   │
                       │   │     (any DDS)       │   │
                       │   └─────────────────────┘   │
                       └─────────────────────────────┘
```

- **Phone is a thick client.** All AI calls, MCP routing, rich
  rendering, and background monitors run on the phone. No cloud
  backend.
- **Connect handles tool calls + streaming.** Streamable HTTP for
  RPC; SSE for live topic streams.
- **DDS-agnostic.** Works with Fast-DDS, CycloneDDS, Zenoh, Connext.
- **Writes require user approval.** Every write tool prompts the
  user in-app before dispatch.

Full architecture: <https://phaneron-robotics.github.io/scry-docs/architecture/>

## Quickstart

### On your robot

```bash
# One-liner installer for Ubuntu + ROS 2 (jazzy / humble / rolling)
curl -fsSL https://raw.githubusercontent.com/phaneron-robotics/scry/main/robot-setup/install.sh | bash

# Or via pip:
pip install scry-connect
scry-connect serve

# Or via Docker:
docker run --rm --network host -e ROS_DOMAIN_ID=0 \
  phaneronrobotics/scry-connect:latest
```

Open the printed QR code, then:

### On your phone

1. Install Scry from [Google Play](https://play.google.com/store/apps/details?id=com.scry) *(coming soon)*
2. Open the app, tap **Add robot**
3. Tap your robot on the radar, scan the QR
4. Ask a question — *"why is /cmd_vel not publishing?"*, *"plot the
   IMU for 5 seconds"*, *"which robot in my fleet is missing /gps?"*

## Running the full stack locally (developer)

Useful for testing without a physical robot — runs a Gazebo
simulation + scry-connect together.

```bash
git clone https://github.com/phaneron-robotics/scry.git
cd scry/robot-setup
docker compose -f docker-compose.sim.yml up
```

The connect listens on `http://localhost:5339`. Point your phone (or
emulator) at it.

For development mode (live-reload connect against your local
checkout):

```bash
docker compose -f docker-compose.dev.yml up
```

## Documentation

- **[Getting started](https://phaneron-robotics.github.io/scry-docs/robot-setup-guide/)**
- **[Architecture](https://phaneron-robotics.github.io/scry-docs/architecture/)**
- **[MCP tools reference](https://phaneron-robotics.github.io/scry-docs/mcp-tools-reference/)**
- **[AI provider strategy](https://phaneron-robotics.github.io/scry-docs/ai-provider-strategy/)**
- **[Development roadmap](https://phaneron-robotics.github.io/scry-docs/development-phases/)**

## Contributing

We welcome contributions. Each component has its own repository — pick
the one your change applies to:

- App bugs / new screens → `scry-android`
- New MCP tools / ROS bugs → `scry-connect`
- Docs typos / improvements → `scry-docs`

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full flow.

## License

[Apache License 2.0](LICENSE). Copyright © 2026 Phaneron Robotics, Inc.

Brand assets (logos, icons, name) are NOT covered by the Apache
license — see [scry-brand](https://github.com/phaneron-robotics/scry-brand)
for usage rules.

## About

Scry is maintained by [Phaneron Robotics, Inc.](https://www.phaneronrobotics.com/),
a Delaware C-corp focused on developer tools for robotics teams.
