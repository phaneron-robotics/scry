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
| Write files outside its allowed roots (bag dir, scratch dir, configured export roots) | Too large a blast radius for a mistake |
| Forward network traffic or open proxies | Same |
| Install system or Python packages | Same |
| Bypass ROS 2 to talk to the network directly | Scry stays middleware-agnostic |
| Stream raw high-rate sensor feeds | Returns thumbnails and decimated samples instead, to stay light over the network |

Running **shell commands on the robot** is a special case: it's **off by
default**. The shell tools are disabled in the connect's default open
mode and only become available when the operator explicitly starts the
connect with `--allow-open-exec` (or runs it in token / mTLS mode). Even
then, every command still asks for your tap-to-approve on the phone and
is recorded in the audit log when one is configured. See
[What Scry can do → Host shell tools](mcp-tools.md#host-shell-tools).

Reading the robot is always allowed; anything that *changes* the robot
asks for your approval on the phone first.
