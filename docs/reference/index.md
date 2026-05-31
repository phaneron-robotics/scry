# Reference

Look-up material, not a read-through.

- **[What Scry can do](mcp-tools.md)** — everything `scry-connect`
  exposes for Scry to inspect and act on, grouped by area, and which
  actions ask for your approval.
- **[Permissions](permissions.md)** — every phone permission the app
  requests, when, and why.

## What Scry deliberately can't do

For safety, `scry-connect` keeps a tight boundary. It does **not** let
the assistant:

| Capability | Why it's excluded |
|---|---|
| Run arbitrary shell commands | Too large a blast radius for a mistake |
| Write files outside its own log area | Same |
| Forward network traffic or open proxies | Same |
| Install system or Python packages | Same |
| Bypass ROS 2 to talk to the network directly | Scry stays middleware-agnostic |
| Stream raw high-rate sensor feeds | Returns thumbnails and decimated samples instead, to stay light over the network |

Reading the robot is always allowed; anything that *changes* the robot
asks for your approval on the phone first.
