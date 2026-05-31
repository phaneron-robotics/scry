# Get started

The 15-minute path from zero to "the AI agent is answering questions about
my robot." Four steps, in order:

1. **[Install Scry on Android](install-android.md)** — closed beta on
   Play Store Internal Testing, or sideload the AAB from GitHub Releases.
2. **[Install scry-connect on the robot](install-connect.md)** — Docker
   sidecar, one-line installer, or `pip install`. Pick what fits your
   robot's deployment.
3. **[Pair the phone and robot](pair.md)** — scan the QR the connect
   prints on first start. WiFi-local, no cloud round-trip.
4. **[First debugging session](first-session.md)** — ask the agent
   `what's my robot's health?` and see what it does.

## Prerequisites

| What | Why | Minimum |
|---|---|---|
| Phone running Android | The app | Android 9 (API 28) |
| ROS 2 robot | Obviously | Humble, Iron, Jazzy, Kilted, or Rolling |
| Same WiFi | Phone talks directly to robot | 2.4 / 5 GHz, no enterprise auth |
| AI provider account | The agent needs a brain | OpenRouter free tier works for testing |

## Where this lives in your stack

Scry doesn't replace `rviz`, `foxglove`, or `rqt`. It complements them
for the cases where you're *not* sitting at your workstation: walking
across the room, demoing the robot to a stakeholder, debugging in the
field. Anything you can do in `rqt`, you can ask Scry in plain English.
