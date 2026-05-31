# Scry — Development Phases

## Phase Overview

| Phase | Focus | Status |
|-------|-------|--------|
| Phase 0 | Scaffolding | Shipped |
| Phase 1 | AI Chat MVP — text/voice/image, ~70 MCP tools, Claude | Shipped |
| Phase 1.5 | Multi-provider + parallel + watchers + UX polish | Shipped |
| Phase 2 | Browse hub + Dashboard + Logs + TF + Processes | Shipped |
| Phase 3 | Rich rendering + live mini-panels + monitors + fleet | Shipped |
| Phase 4 | Reliability + onboarding + packaging | In progress |
| Phase 5 | Testing + Release | Pending |

The roadmap was originally written as a six-phase timeline. Phase 3 grew
into a much larger surface than the original "camera + plot" plan: a full
rich-renderer subsystem (sensor panels, scene snapshots, BT inline,
live mini-panels), multi-step diagnostic plans, edge-triggered background
monitors, fleet overview, robot comparison, and a robot switcher. The
phase table above reflects what's actually shipped.

---

## Phase 0: Scaffolding — Shipped

### Robot Side (scry-connect)
- [x] Python project with `pyproject.toml` and package structure
- [x] MCP server skeleton using `mcp` SDK on Streamable HTTP :5339
- [x] `ros_list_topics` proves MCP works
- [x] rclpy node + manager facade
- [x] Test with MCP Inspector tool

### Android Side
- [x] Project setup (Kotlin, Compose, Hilt, Room, OkHttp)
- [x] Theme (graphite + green dark palette, Material 3, JetBrains Mono for data)
- [x] Navigation scaffold (5-tab bottom nav: Fleets / Robot / Scry / ROS / Settings)
- [x] Rosbridge WebSocket client class stub (`data/rosbridge/RosbridgeClient.kt`) — present but dormant; SSE through scry-connect is the active path
- [x] Connection screen with saved-robot list

### Gate
- [x] Phone connects to connect on robot
- [x] Phone displays list of topics
- [x] MCP server responds to `tools/list`

---

## Phase 1: AI Chat MVP — Shipped

### Robot Side
- [x] 100+ MCP tools across **per-verb manager classes**: topic, service, node, param, action, lifecycle, pkg, component, ros2_control, daemon, multicast, doctor, extensions, interface, bag, dds/env, diagnostics, tf, process, system, watcher, behavior_tree, teleop, docker
- [x] Permission model: every tool tagged `write=True`/`False`. Mirrored on the Android side via `McpToolCatalog.WRITE_TOOLS`; CI parity test keeps the two in sync.
- [x] Shell-backed managers route through a single `shell_runner` with bounded timeouts and structured errors
- [x] rclpy-backed managers share one node + multi-threaded executor on a background thread
- [x] MCP resources: `ros://system/info`, `ros://topics/{name}/schema`, `ros://nodes/{name}/info`
- [x] Image handling: CompressedImage/Image → resize to 512×512 → base64 JPEG
- [x] Safety: rate limiting (token bucket), subprocess timeouts, structured errors (`NotFound`, `Timeout`, `InvalidArgument`, `CliNotAvailable`)
- [x] SSE streaming endpoint (`GET /stream?topic=…`)

### Android Side
- [x] MCP client (HTTP Streamable transport, `McpClient`)
- [x] AI provider abstraction (`AiClient` interface)
- [x] Claude API client with streaming responses
- [x] Tool-call proxy loop (`AiProxyLoop` — AI → phone → MCP → phone → AI)
- [x] Chat UI: message list, text input, streaming text display
- [x] Tool call progress indicators (collapsible cards)
- [x] Write operation confirmation dialogs
- [x] Markdown rendering in chat messages
- [x] Voice input (SpeechRecognizer)
- [x] Image attachment (camera capture + gallery pick)
- [x] Chat history persistence (Room, per-robot)
- [x] Connection management (add/edit/delete robots, saved in Room)

### Gate
- [x] User connects → text → AI calls MCP tools → diagnosis
- [x] Voice input works
- [x] Image attachment works
- [x] Write operations show confirmation dialog
- [x] Chat history persists across app restarts

---

## Phase 1.5: Multi-provider + parallel + watchers + UX polish — Shipped

### Robot side (connect)
- [x] **`WatcherManager`** — four long-running tools that observe ROS events for up to 60 s:
  - `ros_watch_topic(topic, duration, condition?, max_events)` — subscribes, optionally stops early when a condition like `pose.x > 5` matches
  - `ros_watch_diagnostics(duration, level_filter?)` — captures /diagnostics with level filtering
  - `ros_watch_node(node, duration, poll_interval)` — detects appearance/disappearance (crash/restart)
  - `ros_wait_for_topic(topic, timeout)` — blocks until a topic appears (bringup debugging)
- [x] Safe condition expression parser (no eval, dotted paths, comparison operators)
- [x] Write tool registry kept in sync with Android `McpToolCatalog.WRITE_TOOLS` via drift test

### Android side
- [x] **Parallel tool execution** in `AiProxyLoop`. Read-only tools run with `async`+`awaitAll`; writes still sequentialise, each gated by per-tool-id `Approvals` deferred
- [x] **Multi-provider**: `OpenAiClient`, `GeminiClient`, `OllamaClient` in addition to `ClaudeClient`. Each handles its own streaming wire format:
  - Anthropic: SSE + `input_json_delta` piecewise tool args
  - OpenAI: SSE + piecewise `tool_calls.function.arguments`
  - Gemini: SSE + atomic `functionCall` parts
  - Ollama: NDJSON + atomic `tool_calls`
- [x] Provider-agnostic history replay (`buildHistory` replays `ToolUse`/`ToolResult` so stateless providers work on session resume)
- [x] **`McpClient` SSE parser fix** — multi-line `data:` continuations, proper unwrap via `jsonPrimitive.content`. Dashboard and Topics parsers made envelope-tolerant.
- [x] **`VerbosityLevel`** (Terse / Normal / Detailed) setting injected into system prompt. System prompt rewritten: technical tone, no emojis, tables for structured data, parallel reads preferred
- [x] **Hold-to-talk mic** with `SpeechRecognizer` + live partial transcripts + auto-send on release
- [x] **UI overhaul** — graphite + green dark palette, softer accents, typographic hierarchy, suggestion chips, quick-action pills above the input bar, compact tool cards with expand-for-input
- [x] **Settings** redesigned — bottom-sheet API key entry, per-provider model pickers via top-bar chip, verbosity selector, Ollama URL field

### Gate
- [x] Switch provider in top-bar chip → next chat uses the new provider without restart
- [x] AI asks multiple read questions in one turn → connect sees concurrent requests
- [x] Multiple write tool requests queue per-tool approval dialogs
- [x] Hold mic, speak, release → message auto-sends
- [x] Dashboard and Topics render real data (regression from v1 parser bug)

---

## Phase 2: Browse hub + Dashboard + Logs + TF + Processes — Shipped

### Android Side
- [x] **Dashboard ("Robot" tab)** — sectioned, honest. Identity / Graph / Liveness / Diagnostics / DDS health (opt-in probe). No fabricated traffic-light verdicts; every value is a fact. See `ui/dashboard/`.
- [x] **Browse hub ("ROS" tab)** — single hub for ten entity families:
  - Topics — list + detail with live JSON tree + rolling Hz/bw via `ros_read_topic` polling loop
  - Nodes — `ros_inspect_node`, tap pubs/subs/srvs to drill in
  - Services — request/response schema tree
  - Actions — goal/result/feedback schema tree
  - Lifecycle — state badges + available transitions
  - Parameters — per-node parameter tree
  - Components — loaded plugins per container
  - **Logs (`/rosout`)** — live SSE + recent history, level/node/grep filters, severity stripe, auto-scroll-lock with "↓ N new" pill. Per-node logs reachable from Node Detail.
  - **TF** — depth-flattened tree from `ros_tf_frames`, broadcaster + rate per row, orphan-frame warning; Frame Detail with live 2 Hz `ros_tf_lookup`.
  - **Processes** — system-wide ROS-related ps view via `ros_list_system_processes`; sortable by cpu/mem/pid/name; stats card + stdout tail for Scry-launched.
- [x] All list screens share `EntityListScaffold` (search + sort + pin + refresh)
- [x] Pinned items per `(kind, robotId)` persist in `SecurePrefs.pinnedItems`
- [x] "Ask Scry about this" hand-off → seeded chat (`Routes.chatWithSeed`)
- [x] Dashboard diagnostic warnings tappable → seeded "Investigate" chat
- [x] Connect SSE rewrite: persistent subscription, real ROS Hz/bw/count, image throttle, /clock+/tf throttle

### Gate
- [x] Dashboard shows real robot health data
- [x] Topic browser lists all topics with search, sort, pinning, hidden toggle
- [x] Topic detail shows live messages updating in real-time
- [x] JSON tree view renders nested message structures with copy-path
- [x] "Ask Scry about /topic" round-trip works end-to-end

---

## Phase 3: Rich rendering + live mini-panels + monitors + fleet — Shipped

Originally scoped as "camera + plot" — grew into a full rich-renderer
subsystem because the AI's natural output for spatial / temporal /
multi-field data is unintelligible as raw JSON. Driving principle: **trust
the renderer**. The AI's prose adds context and anomaly callouts; the
card carries the data.

### Rich-renderer subsystem (`ui/chat/rich/`)
- [x] **RichDispatcher** — routes tool results to inline blocks by `render_hint` or by tool name. See `RichRenderer.kt`.
- [x] **GroupedList** — namespace-grouped topic / node / service / process lists with pub/sub badges, `0 sub` flagged red
- [x] **Tree** — TF tree with per-edge rate badges
- [x] **EntityCard** — TF lookup, node inspection, parameter description
- [x] **StatusBanner** — health / doctor / diagnostics with OK / WARN / ERROR tone
- [x] **Metric card** — single big number + sparkline, tone-coloured by threshold (Hz / bw / delay)
- [x] **LineChart** — multi-series rolling chart from `ros_read_topic count≥2` or `ros_watch_topic`
- [x] **LogViewer** — level chips, search, virtualised list (for `ros_get_recent_logs`)
- [x] **SceneSnapshot** — composed top-down view: occupancy grid + base_link silhouette + scan dots + path overlay + scale bar (from `ros_read_scene`)
- [x] **GpsView** — OSM map + marker + trail (for `sensor_msgs/NavSatFix`)
- [x] **ImagePreview** — FeedTile chrome (topic chip, dim/format chip, tap-to-zoom)
- [x] **SensorPanel** — same renderer as the Viz tab: Imu attitude / Battery cells / Range cone / MagneticField arrow / Wrench bars / Joy sticks / scalar gauges
- [x] **BtTreeView** — full behaviour-tree map inline (auto-fit, kind-coloured nodes, status-coloured borders). Re-uses Viz-tab `BtSnapshotCanvas` for parity.
- [x] **ConfirmationCard** — auto-rendered when AI announces a write (per the `writes` skill); shows args with diff against current value for `ros_set_parameter`
- [x] **JsonTreeView** fallback

### Live mini-panels (`render_panel`)
- [x] Phone-side meta tool `render_panel(topic, kind, duration_s, fields)` — embed 1–30 s SSE-driven mini-panel into chat
- [x] `kind ∈ {sensor, plot, scene, gps, camera}`; plot takes `fields: [dot-path]` for multi-series overlay
- [x] `render_scene_live(map_topic?, pose_topic?, scan_topic?, path_topic?, duration_s)` — composed live scene (parallel SSE per layer, single canvas)
- [x] Settles into Frozen final frame or Failed("no messages received")

### Diagnostic plans (`emit_plan`)
- [x] Phone-side meta tool for any debugging request needing ≥3 tool calls
- [x] Checklist of `{label, tool, status, outcome?}` rendered as a `PlanBlock`
- [x] Re-emit with updated status + `verdict` once concluded

### Background monitors (`monitor_threshold` / `cancel_monitor`)
- [x] Edge-triggered watch on a topic field — alerts fire only on entry to tripped state, not continuously
- [x] App-scoped `MonitorRegistry` (Hilt singleton, `SupervisorJob + Dispatchers.Default`) drives one SSE subscription per active monitor
- [x] Alerts post into chat as assistant messages via `ChatRepository.append`
- [x] **MonitorChipStrip** — sticky strip between header and chat showing every active monitor with cancel button
- [x] Returns `id` for explicit cancellation

### Fleet + comparison
- [x] **`fleet_overview`** — pings every saved robot in parallel via `MCP.healthCheckTimed`; renders FleetOverviewBlock with online dot, ping ms, per-robot summary
- [x] **`compare_robots(left_name, right_name, dimension, rows)`** — RobotComparisonBlock with two-column metric grid + diff-tinted right column
- [x] **Robot switcher** — chat header robot-name row is tappable → DropdownMenu lists every saved robot with the active one highlighted; switching swaps `ActiveRobotStore` and rebinds the session

### Inline visualisation parity
- [x] Camera feeds, IMU, scans, GPS, battery, BT — all render inline in chat the same way they render on the Viz tab; same sensor renderers, same scene canvas, same BT canvas
- [x] `scry://viz?section=…&topic=…` deep-links from prose into the appropriate Viz section
- [x] Suggestion chips on empty chat surface every Phase 2/3 capability (39 prompts in `assets/prompts/suggestions.txt`)

### Anomaly callouts
- [x] Auto-overlays on sensor cards: Battery (low <20 %, critical <10 %), Range (out of bounds), Imu (>3g critical), MagneticField (outside 10–100 µT), Wrench (50 N / 5 Nm envelope), scalar gauges (per `ScalarConfig.spec`)
- [x] Same overlays apply identically on Viz tab and in chat (`anomalyFor` / `chatAnomalyFor`)

### Skills + Tier-0 prompt
- [x] **`presentation.md`** skill — reference for matching tool output to renderers; trimmed to ~1.5 K tokens
- [x] **`writes.md`** skill — write-op announcement protocol
- [x] System prompt updated with the 6 new core meta-tools

### Gate
- [x] Tool result → rich block render works for every block class
- [x] `render_panel` / `render_scene_live` settle within `duration_s + 1`
- [x] `monitor_threshold` survives app backgrounding; alert appears as chat message on trip
- [x] Switching robot from chat header rebinds session without crash
- [x] Anomaly badges appear identically in chat and Viz tab

---

## Phase 4: Reliability + onboarding + packaging — In progress

### Android Side
- [x] Multi-robot quick switch — chat header dropdown (shipped as part of Phase 3)
- [x] AI providers wired and shipping: **OpenRouter** (unified default, 300+ models) plus single-provider clients (Claude, OpenAI, Gemini, Ollama) — Phase 1.5
- [x] Settings screen with credential entry per provider
- [ ] Error handling: structured network errors, timeouts, reconnection with backoff
- [ ] Connection health monitoring (periodic connect ping, auto-reconnect on flap)
- [ ] App icon and splash screen
- [ ] Onboarding flow (first launch → set up AI provider → connect robot)
- [ ] Performance: memory profiling under long-running monitors + scene SSE, battery profiling, cold-start measurement on mid-range Android
- [ ] Edge cases: very large messages, missing topics, slow networks, SSE reconnect with backoff

### Robot Side
- [ ] Install script (`robot-setup/install.sh`)
- [ ] Dockerfile (with `--public-internet` and `--token` flags wired through compose)
- [ ] Optional systemd service file (`scry.service`)

### Live BT status streaming (deferred from Phase 3)
- [ ] `render_bt_live` phone-side tool — subscribe to `/behavior_tree_log` for ~10 s and replay status updates into the inline BT canvas. Canvas already accepts `nodeStates`; wiring is mechanical. (See note at end of Phase 3 — pattern matches `render_scene_live`.)

### Gate
- Switch between 2+ robots without crashes (already gated by Phase 3)
- App handles network disconnection gracefully (TODO)
- Settings persist correctly ()
- First-run onboarding completes in <2 min (TODO)

---

## Phase 5: Testing + Release — Pending

### Testing
- [x] **Drift detectors** — `tests/test_tools_registry.py` (core-set parity + write classification), `tests/test_skill_tool_references.py` (skill → tool reference check, token budget)
- [ ] Unit tests: ViewModels, protocol parsing, tool proxy logic
- [ ] UI tests: chat rendering, navigation, topic list (Compose Test)
- [ ] E2E tests: physical device + robot running turtlesim
- [ ] Test with multiple robot types (TurtleBot, custom robots)
- [ ] Test all MCP tools against real ROS 2 environment
- [ ] Test with different DDS implementations (Fast-DDS, CycloneDDS)
- [ ] Battery / performance testing on mid-range Android device
- [x] Security audit pass — see `docs/SECURITY_AUDIT.md` (all C/H closed, M-2/M-3 deferred with explicit trade-offs)

### Release Prep
- [ ] Play Store listing (screenshots, description, icon)
- [ ] PyPI package for scry-connect
- [ ] User documentation (README, quick start guide)
- [ ] Beta distribution (internal testing track on Play Store)

### Gate
- All tests pass
- Beta tested with 3+ different robot setups
- Play Store review submitted
- scry-connect published on PyPI

---

## Key Test Scenarios

1. **Happy path**: Connect → ask question → get diagnosis with tool calls
2. **Network interruption**: Robot disconnects mid-chat → graceful recovery
3. **High-frequency topic**: Subscribe to 100 Hz IMU → throttling works, no OOM
4. **Large messages**: PointCloud2 or large image → graceful handling
5. **Camera + chat**: Streaming camera while chatting → no blocking
6. **Write confirmation**: AI proposes publish / lifecycle transition / controller switch → user approves/denies → correct behaviour
7. **Multi-robot**: Connect to 2 robots, switch from chat header → correct context isolation
8. **Long conversation**: 50+ messages → tiered-context system keeps prompt under budget
9. **Ollama local**: Works without internet connectivity
10. **Different DDS**: Works with Fast-DDS, CycloneDDS, Zenoh — `ros_get_dds_env` surfaces the right variables per middleware
11. **ros2_control fleet**: Ask "which controllers are active?" → connect returns manager state without needing shell access
12. **Lifecycle flow**: AI proposes `configure → activate` on a Nav2 node → user approves each transition individually
13. **Live mini-panel**: "Plot /cmd_vel linear.x and angular.z for 5 s" → multi-series chart embedded in chat
14. **Live scene**: "Show the robot moving on the map for 10 s" → composed top-down view (map + pose + scan + path) embedded in chat
15. **Monitor**: "Tell me if /battery drops below 20 %" → monitor strip appears, alert fires on trip, auto-disarms while still tripped
16. **Fleet overview**: "How's the fleet?" with 2+ saved robots → online dot + ping ms per robot
