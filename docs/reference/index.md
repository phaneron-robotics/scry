# Reference

The exhaustive catalog. Use as a lookup, not a read-through.

- **[MCP tools](mcp-tools.md)** — every tool `scry-connect` exposes,
  parameters, return shape, examples, which require user approval.
  103 entries.
- **[Permissions](permissions.md)** — every Android runtime permission
  Scry requests, when, and why.

## What scry-connect doesn't ship

For comparison, here's what an MCP-for-ROS server *could* expose but
scry-connect deliberately omits:

| Capability | Status | Reason |
|---|---|---|
| Arbitrary shell exec | Not exposed | Massive blast radius for AI mistakes |
| File system write outside `/var/log/scry` | Not exposed | Same |
| Network proxy / port forwarding | Not exposed | Same |
| Package install (apt, pip, etc.) | Not exposed | Same |
| Direct DDS access (bypassing rclpy) | Not exposed | RMW-agnostic is a goal |
| Streaming sensor data (live camera, lidar) | Via SSE only | Returns thumbnails and decimated samples |

If you want any of the above, fork scry-connect and add the tool —
the registry is straightforward.
