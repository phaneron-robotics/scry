# Scry — System Architecture

## Overview

Scry consists of three runtime environments connected by two communication channels.

```mermaid
flowchart TB
    subgraph Phone["Android phone"]
        UI["Frontend\nCompose · Dashboard · Chat · Topics · Viz"]
        Logic["App logic\nAiClient · McpClient · proxy loop · Room DB"]
        UI -->|"observes StateFlow"| Logic
    end

    subgraph Robot["Robot · Linux"]
        Connect["scry-connect\nHTTP :5339 · 100+ MCP tools · SSE"]
        Bridge["rosbridge · optional\nWebSocket :9090"]
        ROS["ROS 2 runtime\nyour nodes, topics, services"]
        Connect <-->|"rclpy"| ROS
        Bridge <-->|"DDS"| ROS
    end

    Cloud["AI provider\nOpenRouter (cloud, default) · Ollama (local)"]

    Logic <-->|"HTTPS · MCP · SSE"| Connect
    Logic -.->|"WebSocket"| Bridge
    Logic <-->|"HTTPS"| Cloud

    classDef brand fill:#292826,stroke:#3A3835,stroke-width:1px,color:#E8E4D9
    classDef cluster fill:#1C1B19,stroke:#3A3835,stroke-width:1px,color:#9C9A8D
    class UI,Logic,Connect,Bridge,ROS,Cloud brand
    class Phone,Robot cluster
    linkStyle default stroke:#A3B86C,stroke-width:2px,color:#9C9A8D
```

## Communication Channels

### Channel 1: Scry Connect (Required)

| Property | Value |
|----------|-------|
| Protocol | Streamable HTTP (JSON-RPC 2.0) |
| Port | 5339 |
| Purpose | AI agent MCP tool calls + topic streaming via SSE |
| Runs on | Robot |

The connect is the only required component on the robot. It:
- Exposes 100+ MCP tools across categories (topics, services, nodes, params, actions, lifecycle, ros2_control, components, tf, network, diagnostics, processes, behaviour trees, scenes, watchers, teleop, docker, etc.) — see [Tiered Context System](#tiered-context-system) for how the phone slices this catalog
- Exposes MCP resources (system info, topic schemas)
- Provides SSE endpoint for topic streaming (alternative to rosbridge) — `GET /stream?topic=…`
- Uses `rclpy` internally — works with any DDS/RMW implementation
- Advertises itself over mDNS / Zeroconf (`_scry._tcp.local.`, on by default; disable with `--no-mdns`) so the phone's discovery scan finds it on the LAN
- Implements the connect-side write-confirmation handshake (`X-Scry-Confirm` nonce in token/mTLS modes)

### Channel 2: rosbridge (Optional, currently dormant)

| Property | Value |
|----------|-------|
| Protocol | WebSocket (JSON) |
| Port | 9090 |
| Purpose | Reserved for future high-frequency UI streaming |
| Runs on | Robot |

The `RosbridgeClient` Kotlin class exists in the codebase and the connection
screen still asks for a rosbridge port, but the live-data path the app
actually uses is **scry-connect's SSE endpoint** (`GET /stream?topic=…`).
All sensor panels, scene snapshots, line charts, and camera feeds — both
in the Viz tab and the chat rich blocks — pull through SSE. The
rosbridge client is kept dormant for future use; deleting it is a
follow-up.

### Why one channel today

Connect SSE turned out to be enough:

- Real connect-side stats (Hz from callback timing, bandwidth from
  `serialize_message()`, true delivered count) ride on every event
- `/clock`, `/tf*`, and image topics are auto-throttled server-side so a
  100 Hz IMU subscription doesn't melt the phone
- Tool calls and streams share the same auth posture, audit log, and
  safety envelope — there's no second surface to harden

If a future feature needs WebSocket-style pub/sub from the UI layer, the
`RosbridgeClient` shell is already wired into Hilt.

## The Proxy Pattern

The cloud AI provider (OpenRouter by default) runs off-network and cannot reach robots on private WiFi. The phone bridges this gap:

```
AI provider  ←──REST──→  Phone App  ←──HTTP──→  Robot MCP Server
  (cloud)                (WiFi)                  (LAN)
```

1. User asks a question in the chat
2. Phone sends message to the AI provider with MCP tool definitions
3. The model responds with `tool_use` blocks
4. Phone forwards each tool call to robot's scry-connect via HTTP
5. Connect executes rclpy operations, returns results
6. Phone sends `tool_result` back to the model
7. The model analyzes and responds
8. Phone renders response in chat UI

This loop repeats until the model provides a final text response. (With the local Ollama provider, the same loop runs entirely on the LAN — no cloud hop.)

## Tiered Context System

The phone uses a three-tier context system to keep the per-turn prompt
small for simple questions while still letting the model pull in deep
domain knowledge when it needs to. Everything stays on-phone — no
backend, no embeddings, no RAG.

```
┌─────────────────────────────────────────────────────────┐
│  TIER 0 — Always loaded (~1.2K tokens)                  │
│                                                         │
│  • assets/prompts/system_prompt.md  (the slim prompt)   │
│  • Core MCP tools tagged `category="core"` in the       │
│    connect registry: ros_list_topics, ros_list_nodes,    │
│    ros_list_services, ros_list_actions,                 │
│    ros_list_parameters, ros_inspect_node,               │
│    ros_read_topic, ros_check_health,                    │
│    ros_get_recent_logs                                  │
│  • Two phone-side meta tools: load_skill, load_toolset  │
└─────────────────────────────────────────────────────────┘
                          │
                          │  load_skill("...") / load_toolset("...")
                          ▼
┌─────────────────────────────────────────────────────────┐
│  TIER 1 — Skills (assets/skills/*.md, on demand)        │
│                                                         │
│  debugging, performance, tf, lifecycle, parameters,     │
│  control, network, logs, writes, presentation           │
│                                                         │
│  Each ≤1500 tokens. Skill content is appended to the    │
│  system prompt for the rest of the session.             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  TIER 2 — Toolsets (connect categories, on demand)       │
│                                                         │
│  Categories: performance, tf, lifecycle, parameters,    │
│  control, process, components, packages, interfaces,    │
│  network, logs, watchers, services, etc.                │
│                                                         │
│  load_toolset("category") expands the available tool    │
│  list with every tool the connect tagged with that       │
│  category.                                              │
└─────────────────────────────────────────────────────────┘
```

### How it's wired

- **Connect** (`scry_connect/tools/registry.py`) tags every registered
  tool with a `category` field. `core` is the always-loaded set; the
  rest are domain groupings.
- **Connect** exposes `GET /tools/categories` returning
  `{"tool_to_category": {...}, "categories": {...}}` so the phone can
  slice the catalog without polluting MCP `tools/list`.
- **Phone** (`McpToolCatalog`) caches the tool list + category map for
  five minutes. `coreTools()` and `categoryTools(name)` give the
  proxy loop the slices it needs per turn.
- **Phone** (`SkillLoader`) reads markdown from `assets/skills/`. Cached
  in memory; ships in the APK.
- **Phone** (`AiProxyLoop`) recognises `load_skill` and `load_toolset`
  by name, resolves them locally, and **does not** forward them to the
  robot. The session's `SessionContext` accumulates loaded skills
  (whose markdown is appended to the system prompt) and loaded toolsets
  (whose schemas are appended to the tool list).
- **Per-turn request build**: each iteration of the proxy loop
  recomputes
  `systemPrompt = Tier-0 prompt + sessionContext.systemPromptTail()`
  and
  `tools = coreTools + load_skill + load_toolset + sessionContext.expandedTools`.

### Token-budget targets

| Scenario | Goal |
|---|---|
| Simple query ("topic list", "list nodes") | ~1.2K tokens |
| Mid-complexity (single inspection) | ~2.5K tokens |
| Deep debug ("why is X broken") | ~4–5K tokens (1–2 skills loaded) |

Worst-case pathological session loading three skills + writes is
capped at ~3500 tokens of skill content (CI-checked by
`tests/test_skill_tool_references.py::test_skill_token_budget`).

### Drift detectors

- `tests/test_tools_registry.py::test_core_tools_match_tier0_prompt`
  asserts the connect's `core` set equals the names listed in the
  Tier 0 prompt's "Core tools" section. Adding to `core` bloats every
  turn; removing breaks the prompt's decision examples.
- `tests/test_skill_tool_references.py::test_every_referenced_tool_exists`
  scans every skill markdown file and asserts every backticked
  `ros_*` identifier matches a registered tool — so a skill can never
  tell the model to call something that doesn't exist.

### Dev panel

`SecurePrefs.showContextStats` toggles a small in-chat banner showing
the current `SessionContext.Snapshot` — turn count, loaded skills,
loaded toolsets, approximate tokens added. Toggle from
**Settings → Developer → Show tiered-context stats in chat**.

## DDS / Middleware Agnostic

scry-connect uses `rclpy`, which talks through the ROS 2 RMW (ROS Middleware) abstraction layer. This means it works with:

- **eProsima Fast-DDS** (default in most ROS 2 distros)
- **Eclipse CycloneDDS**
- **Zenoh** (via rmw_zenoh)
- **RTI Connext**
- Any future RMW implementation

The user's `RMW_IMPLEMENTATION` environment variable determines which middleware is used. scry-connect doesn't care — it only talks to rclpy.

## Data Flow Examples

### AI Chat (Primary Feature)

```
User: "Why is my robot drifting left?"
  │
  ▼
Phone → Claude API: {message + 23 tool definitions}
  │
  ▼
Claude → Phone: tool_use[ros_read_topic("/cmd_vel", count=5)]
  │
  ▼
Phone → Robot:5339: MCP tools/call {ros_read_topic, args}
  │
  ▼
Robot → Phone: {cmd_vel messages}
  │
  ▼
Phone → Claude: tool_result[{cmd_vel data}]
  │
  ▼
Claude → Phone: tool_use[ros_get_parameter("/diff_drive", "wheel_radius")]
  │
  ▼
... (more tool calls as needed) ...
  │
  ▼
Claude → Phone: "Left wheel radius is 0.033m but right is 0.035m..."
  │
  ▼
Phone: renders diagnosis in chat UI
```

### Topic Monitoring (via rosbridge)

```
Phone → Robot:9090: {"op":"subscribe", "topic":"/imu", "throttle_rate":100}
  │
  ▼
Robot → Phone: {"op":"publish", "topic":"/imu", "msg":{...}}  (continuous)
  │
  ▼
Phone: renders in topic browser / chart
```

### Topic Monitoring (via scry-connect SSE, no rosbridge)

```
Phone → Robot:5339: GET /stream?topic=/imu&rate=10
  │
  ▼
Robot → Phone: SSE event: {imu data}  (continuous)
  │
  ▼
Phone: renders in topic browser / chart
```

### ROS hub (Phase 2)

The **ROS** tab (label "ROS"; route id `topics` for historical compatibility)
is a single hub that lists ten inspectable ROS entity families: topics,
nodes, services, actions, lifecycle nodes, parameters (per node),
component containers, **logs** (`/rosout` live + recent history with
level/node/grep filters), **TF** (frame tree with broadcaster + rate +
live `tf_lookup` panel), and **processes** (system-wide ps view of
ROS-related processes). Tapping a tile opens that family's list screen;
tapping a row opens its detail.

The Logs view uses the same persistent SSE pattern as Topic Detail
(`GET /stream?topic=/rosout`) plus a one-shot `ros_get_recent_logs` for
history, so the screen is informative even before the user taps Play.
Per-node logs is the same screen with a `nodeFilter` arg pre-applied,
launched from the "View logs" link in Node Detail; an honesty banner
calls out that terminal stdout from non-Scry-launched nodes isn't
accessible. The Processes tile relies on a new connect tool
`ros_list_system_processes` that filters `ps` output to ROS-related
commands and cross-references Scry's own process tracker so own-launched
processes can offer stdout-tail / kill controls.

```
BottomNav "ROS" → Routes.TOPICS (BrowseHubScreen)
                       │ counts: 7 catalog tools fired in parallel
                       ▼
                  ┌────────┬────────┬─────────┬─────────┬───────────┬───────────┬────────────┐
                  │ Topics │  Nodes │ Services│ Actions │ Lifecycle │  Params   │ Components │
                  │ /list  │ /nodes │ /svcs   │ /acts   │ /lifecycle│ /parameters│ /components│
                  └───┬────┴────┬───┴────┬────┴────┬────┴─────┬─────┴────┬──────┴─────┬──────┘
                      ▼         ▼        ▼         ▼          ▼          ▼            ▼
                  detail     detail   detail   detail     detail   per-node     container
                                                                    params       detail
```

All list screens share `EntityListScaffold` (search + sort + pin + refresh).
All detail screens share the "Ask Scry" pattern: a star icon hands off to chat
with a context-rich seed prompt (`Routes.chatWithSeed(seed)`), so writes
flow through the existing tool-approval gate rather than a parallel form
surface. Pinning is per `(kind, robotId)` in `SecurePrefs.pinnedItems`.

### Topic Detail (Phase 2 — connect-poll, no rosbridge)

The topic detail screen uses a polling loop over `ros_read_topic` instead of
rosbridge or SSE. This keeps the surface deployable against a scry-connect-only
robot and reuses the connect's QoS-matching helper (so `SensorDataQoS`
publishers — lidar, camera, IMU — actually deliver). When the screen is
visible and not paused the view-model issues `ros_read_topic count=1,
timeout=2.0` in a tight loop; each delivery feeds the JSON tree, the rolling
30-sample Hz/bandwidth meter, and the message counter. Pause stops the loop;
resume restarts it. The "Ask Scry" button hands off via
`Routes.chatWithSeed(...)` — the chat screen pre-fills the input with a
"Investigate /topic …" prompt and lets the user tap Send.

```
TopicsScreen → row tap → topics/detail/{name encoded}
  │
  ▼
TopicDetailViewModel.start(topic):
  - ros_topic_info verbose=true   (one-shot — pubs, subs, QoS)
  - ros_read_topic count=1 (loop) → rolling Hz/bw + JsonTreeView render
  - "Ask Scry" → Routes.chatWithSeed("Investigate <topic> — …")
                                     → ChatScreen seeds input
                                     → user taps Send → AiProxyLoop
```

The same seed-chat hand-off is wired from Dashboard diagnostic warnings
(tap "Investigate →" on a WARN/ERROR row). Together they form the
"see something → ask AI to explain it" loop that Phase 2 was meant to close.

## Rich-renderer subsystem (Phase 3)

The chat surface is not a plain-text log. Tool results are dispatched
through `RichDispatcher` (`ui/chat/rich/RichRenderer.kt`) to a set of
inline blocks that render the same way the dedicated Viz tab does — the
two paths share the same canvases and sensor renderers, so the chat view
of a behaviour tree, a scan, an IMU, or a map is identical to the Viz
tab (modulo gestures).

```
AI tool result
     │
     ▼
RichDispatcher
     ├─ render_hint present?  → dispatch on hint
     ├─ otherwise              → dispatch on tool name
     ▼
┌─ Inline rich blocks (ui/chat/rich/blocks/) ────────────────────┐
│  StatusBanner   Metric        LineChart      LogViewer         │
│  GroupedList    Tree          EntityCard     ConfirmationCard  │
│  SensorPanel    SceneSnapshot GpsView        ImagePreview      │
│  BtTreeView     LivePanel     LiveScene      PlanBlock         │
│  FleetOverview  RobotCompare  JsonTreeView (fallback)          │
└────────────────────────────────────────────────────────────────┘
```

### Phone-side meta-tools

A small set of tools live entirely on the phone — they never round-trip
to the connect:

| Tool | Purpose |
|---|---|
| `load_skill` / `load_toolset` | Tiered-context expansion (see above) |
| `render_panel` | Embed a 1–30 s SSE-driven mini-panel into chat (`kind ∈ sensor / plot / scene / gps / camera`) |
| `render_scene_live` | Composed live scene — parallel SSE per `map_topic` / `pose_topic` / `scan_topic` / `path_topic` into one canvas |
| `emit_plan` | Render a multi-step diagnostic checklist with per-step status and a final verdict |
| `monitor_threshold` / `cancel_monitor` | Register/cancel an edge-triggered background watch on a topic field |
| `fleet_overview` | Ping every saved robot in parallel and render a per-robot card |
| `compare_robots` | Side-by-side metric grid for two saved robots |

`AiProxyLoop.handlePhoneSideTool` resolves these locally; the AI sees
them in `tools/list` like any other tool.

### Background monitors

`MonitorRegistry` (`data/monitor/MonitorRegistry.kt`) is a Hilt singleton
with an app-scoped `SupervisorJob + Dispatchers.Default`. Each active
monitor owns one SSE subscription and is **edge-triggered** — an alert
fires only when the predicate flips false→true. The chat surface shows
a `MonitorChipStrip` between the header and the message list while any
monitor is armed; tapping a chip's cancel button calls `cancelAll()` /
`cancel(id)`.

Alerts post into the chat as assistant messages via
`ChatRepository.append`, so they survive app restarts and show up in
history exactly like a normal AI turn.

## Security Model

### Safety — User confirmation

All write operations require explicit user approval in the app:

| Operation | Requires Confirmation |
|-----------|----------------------|
| Read topics, list nodes, get params | No (always allowed) |
| Publish to topic | Yes |
| Call service | Yes |
| Set parameter | Yes |
| Send action goal | Yes |
| Lifecycle transitions | Yes |
| ros2_control writes | Yes |
| Component load/unload/standalone | Yes |

The AI agent proposes an action → the chat surface auto-renders a
`ConfirmationCard` showing the proposed args (with diff against the
current value for `ros_set_parameter`) → the user taps Approve in the
card → only then does `AiProxyLoop` mint the `X-Scry-Confirm` nonce and
dispatch the tool. The exact write set is enforced by
`McpToolCatalog.WRITE_TOOLS` and the connect's `write=True` tags; a CI
parity test keeps the two in sync.

### Network security

The default posture is **open mode on RFC1918 / loopback** — the connect
rejects callers from public IPs unless `--public-internet` is passed.
This matches rosbridge / foxglove_bridge conventions and avoids the SSH
copy-paste friction of mandatory tokens during day-to-day debugging.

Hardening modes are opt-in CLI flags:

- `--token` — pair via QR from the phone; writes require a one-shot
  `X-Scry-Confirm` nonce (`server.call_tool` enforces this server-side)
- `--mtls` — mutual TLS, same nonce requirement
- `--public-internet` — required to bind on a non-RFC1918 address

The AI provider API key (OpenRouter, or a legacy per-vendor key) is
stored in `EncryptedSharedPreferences` (AES-256, backed by Android
Keystore) and sent only to the provider's API.

Full audit + remediation history: `docs/SECURITY_AUDIT.md`.

## Multi-Robot Support

Each robot runs its own scry-connect instance. The app maintains:

- A list of saved robots (IP + ports, stored in Room DB)
- One active connection at a time, swappable mid-session
- Separate chat conversations per robot (sessions are keyed by robot id)
- **Robot switcher in the chat header** — tap the robot-name row to get a
  DropdownMenu of every saved robot; the active one is highlighted

### Fleet-wide queries

Fleet operations are shipped, not deferred — they run on the phone:

- **`fleet_overview`** — phone-side meta tool that pings every saved
  robot in parallel via `McpClient.healthCheckTimed(r)` and renders a
  per-robot card (online dot, ping ms, summary). The AI calls this when
  the user asks "how's the fleet" / "which robots are online".
- **`compare_robots(left_name, right_name, dimension, rows)`** — emits a
  side-by-side metric grid; the AI populates `rows` after fetching each
  side's data with normal per-robot tool calls.

Cross-robot tool calls (one Claude turn calling MCP on robot A *and*
robot B) are intentionally not supported — sessions are per-robot. The
fleet path above runs at the meta-tool layer.
