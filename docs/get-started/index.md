# Get started

The path from zero to "Scry is answering questions about my robot." A
handful of short steps, in order:

1. **[Get the Scry app](install-android.md)** — install it and sign in
   with a free account (Google, GitHub, or email).
2. **[Install scry-connect on the robot](install-connect.md)** —
   one-line installer, `pip install`, or Docker. Pick what fits your
   robot.
3. **[Choose your AI](choose-ai.md)** — add an OpenRouter key (free tier
   available) or point Scry at a local Ollama server.
4. **[Pair the phone and robot](pair.md)** — scan the QR the connect
   prints on first start. Local to your network, no cloud round-trip.
5. **[First session](first-session.md)** — ask Scry
   `what's my robot's health?` and watch what it does.

## Prerequisites

| What | Why | Minimum |
|---|---|---|
| A phone | Runs the app | Android 9 (API 28). iOS coming soon. |
| A ROS 2 robot | The thing you're debugging | Humble, Jazzy, Kilted, Lyrical, or Rolling |
| The same network | Phone talks directly to the robot | Wi-Fi without enterprise/captive-portal auth |
| An AI provider | Powers the assistant | OpenRouter's free tier works to start |

## Where Scry fits

Scry doesn't replace `rviz`, `foxglove`, or `rqt`. It complements them
for the times you're *not* at your workstation — walking across the lab,
demoing the robot, or debugging in the field. Much of what you'd do at a
desktop, you can simply ask Scry in plain English.
