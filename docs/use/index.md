# Use Scry

How to actually drive the app day-to-day, once you're past first install.

- **[Chat with Scry](chat.md)** — the primary surface. Streaming
  responses, inline result rendering, multi-turn context, retry,
  fork, edit.
- **[File attachments and images](attachments.md)** — drop a log file
  or a screenshot into the conversation. Up to 1 MB of text, images
  auto-downscaled to 2048 px.
- **[Voice input](voice.md)** — speak your question; Scry transcribes
  on-device. No audio leaves your phone.
- **[Background monitors](monitors.md)** — edge-triggered alerts when
  a threshold trips. Fires into chat as if Scry posted it.
- **[Connect from anywhere](remote.md)** — use Scry on the same network
  or remotely over a VPN, plus the connect's run-time options.
- **[Sending feedback](feedback.md)** — inline thumbs-up / thumbs-down
  on every reply, plus a form for general impressions, bug reports, and
  feature requests.

## The five tabs

| Tab | What's there |
|---|---|
| **Fleets** | List of paired robots. Add/remove, switch active. |
| **Robot** | Dashboard for the active robot — health, nodes, topics summary. Honest data sheet, no fabricated verdicts. |
| **Scry** | Primary chat surface. Where you spend 90% of your time. |
| **ROS** | Browse hub — 10 ROS entity families (topics, nodes, services, actions, lifecycle, params, components, logs, TF, processes). |
| **Viz** | Long-running visualization — scene, camera, BT, geomap, plot, sensors, teleop. |

The Scry tab is the center button on purpose. Chat is the primary
interaction model; everything else supports it.

## What Scry isn't

- **Not Foxglove.** No comprehensive visualization layer, no recording
  playback, no PlotJuggler-grade timeseries. The Viz tab covers the
  common cases; for deep analysis, use the right tool.
- **Not a remote desktop.** You can't run arbitrary commands on the
  robot — only the safe, well-defined actions `scry-connect` exposes.
- **Not autonomous.** Scry proposes; you approve. Every action that
  changes the robot (publishing to a topic, setting a parameter, calling
  a service) requires an explicit tap before it happens.
