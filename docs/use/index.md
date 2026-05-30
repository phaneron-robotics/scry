# Use Scry

How to actually drive the app day-to-day, once you're past first install.

- **[Chat with the agent](chat.md)** — the primary surface. Streaming
  responses, inline tool result rendering, multi-turn context, retry,
  fork, edit.
- **[File attachments and images](attachments.md)** — drop a log file
  or a screenshot into the conversation. Up to 200 KB text, max 2048 px
  images (auto-downscaled).
- **[Voice input](voice.md)** — Android `SpeechRecognizer` integration.
  No audio leaves the device.
- **[Background monitors](monitors.md)** — edge-triggered alerts when
  a threshold trips. Fires into chat as if the assistant posted it.
- **[Sending feedback](feedback.md)** — inline thumbs-up / thumbs-down
  on every assistant reply, plus a top-level form for general
  impressions, bug reports, and feature requests.

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
  robot — only the 100+ MCP tools the connect exposes. (You can extend
  the connect with custom tools if you need to.)
- **Not autonomous.** The agent proposes; you approve. Every "write"
  tool call (publish to a topic, set a parameter, call a service)
  requires an explicit tap before it dispatches.
