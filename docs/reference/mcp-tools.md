# What Scry can do

This is the full catalogue of what Scry can inspect and do on a robot
through `scry-connect` — **119 capabilities**, grouped by area. Of
these, **37 change the robot** and always require your approval on the
phone; the rest are read-only.

You don't call any of these directly — you ask Scry in plain language
and it picks the right ones. This page is a reference for what's
possible, and a handy vocabulary if you want to be specific (e.g. "check
the publish rate of `/odom`").

## Reads vs. actions

- **Reads** — listing topics, inspecting nodes, checking diagnostics,
  reading parameters — run immediately. They don't change anything on
  the robot.
- **Actions** (marked **write** below) — publishing, setting a
  parameter, calling a service, lifecycle changes, and so on — always
  pause for your tap-to-approve on the phone. Scry shows exactly what it
  intends to do before anything is sent. When you run the connect in
  token mode, an extra one-time approval code is required too. See
  [How Scry works](../how-it-works.md) for the safety model and
  [Connect from anywhere](../use/remote.md) for the connect's modes.

## Capability areas

Scry groups its capabilities into areas — topics, services, nodes,
parameters, actions, lifecycle, performance, transforms (TF), control,
components, packages, interfaces, processes, watchers, diagnostics,
logs, network, bags, doctor, daemon, extensions, build, system, Docker,
Nav2, teleop, host shell, and incidents. The tables below list what's in
each.

## Tool groups

| Group | Read tools | Write tools (need confirmation) |
|-------|-----------|------------------------------|
| Topic | `ros_list_topics`, `ros_find_topics_by_type`, `ros_topic_type`, `ros_topic_info`, `ros_read_topic`, `ros_read_scene`, `ros_topic_hz`, `ros_topic_bw`, `ros_topic_delay` | `ros_publish_topic` |
| Service | `ros_list_services`, `ros_find_services_by_type`, `ros_service_type`, `ros_service_info`, `ros_service_echo` | `ros_call_service` |
| Node | `ros_list_nodes`, `ros_list_nodes_with_resources`, `ros_inspect_node` | — |
| Parameter | `ros_list_parameters`, `ros_get_parameter`, `ros_describe_parameter`, `ros_dump_parameters` | `ros_set_parameter`, `ros_load_parameters`, `ros_delete_parameter` |
| Action | `ros_list_actions`, `ros_action_type`, `ros_action_info` | `ros_send_action_goal`, `ros_cancel_action_goal` |
| Lifecycle | `ros_lifecycle_nodes`, `ros_lifecycle_get`, `ros_lifecycle_list_transitions` | `ros_lifecycle_set` |
| Package | `ros_list_packages`, `ros_pkg_prefix`, `ros_pkg_executables`, `ros_pkg_launch_files`, `ros_pkg_xml` | `ros_pkg_create` |
| Component | `ros_component_list`, `ros_component_types` | `ros_component_load`, `ros_component_unload`, `ros_component_standalone` |
| ros2_control | `ros_control_list_controllers`, `ros_control_list_controller_types`, `ros_control_list_hardware_components`, `ros_control_list_hardware_interfaces`, `ros_control_view_controller_chains` | `ros_control_load_controller`, `ros_control_unload_controller`, `ros_control_set_controller_state`, `ros_control_switch_controllers`, `ros_control_reload_controller_libraries`, `ros_control_cleanup_controller`, `ros_control_set_hardware_component_state` |
| Daemon | `ros_daemon_status` | `ros_daemon_start`, `ros_daemon_stop` |
| Multicast | `ros_multicast_receive` | `ros_multicast_send` |
| Doctor / WTF | `ros_doctor`, `ros_doctor_hello` | — |
| Extensions | `ros_extensions` | — |
| Interface | `ros_list_interfaces`, `ros_show_interface` | — |
| Bag | `ros_bag_info`, `ros_bag_list`, `ros_bag_record_status` | `ros_bag_record_start`, `ros_bag_record_stop` |
| DDS / env | `ros_get_dds_info`, `ros_get_dds_env`, `ros_network_interfaces` | — |
| Diagnostics | `ros_get_diagnostics`, `ros_check_health`, `ros_get_recent_logs`, `ros_liveness`, `ros_graph_diff` | — |
| TF | `ros_tf_frames`, `ros_tf_lookup` | — |
| Watchers | `ros_watch_topic`, `ros_watch_diagnostics`, `ros_watch_node`, `ros_wait_for_topic` | — |
| Process | `ros_list_processes`, `ros_list_system_processes`, `ros_system_processes`, `ros_tail_process` | `ros_run_node`, `ros_run_launch`, `ros_run_script`, `ros_restart_launched`, `ros_kill_process` |
| Build | `ros_list_scratch_files`, `ros_list_workspaces`, `ros_export_file` | `ros_write_scratch_file`, `ros_colcon_build` |
| System | `ros_system_info` | — |
| Behaviour tree | `ros_bt_list_sources`, `ros_bt_get_active_tree`, `ros_bt_status` | — |
| Teleop | — | `ros_teleop_start`, `ros_teleop_set`, `ros_teleop_stop` |
| Docker | `ros_docker_status`, `ros_docker_inspect`, `ros_docker_logs` | — |
| Host shell | `ros_shell_read`, `ros_query_shell_job`, `ros_list_shell_jobs` | `ros_shell_exec`, `ros_kill_shell_job` |
| Incidents | `ros_search_incidents`, `ros_get_incident` | `ros_save_incident` |

---

## Topic tools

### `ros_list_topics`
List active topics with types and pub/sub counts. Equivalent to `ros2 topic list -t`.

| Param | Type | Default | Description |
|---|---|---|---|
| `filter` | string | — | Regex to filter topic names |
| `include_hidden` | bool | `false` | Include `/_*` hidden topics |
| `count_only` | bool | `false` | Return `{"count": N}` instead of the list |

Returns: `[{name, type, publisher_count, subscriber_count}]`

### `ros_find_topics_by_type`
Find topics that publish a given message type. Equivalent to `ros2 topic find`.

### `ros_topic_type`
Get the message type of a topic. Equivalent to `ros2 topic type`.

### `ros_topic_info`
Topic metadata + (with `verbose`) QoS profile of every endpoint. Equivalent to `ros2 topic info [-v]`.

### `ros_read_topic`
Subscribe, collect N messages, unsubscribe. Images are downscaled to fit within 512×512 (aspect ratio preserved) and returned as base64 JPEG. Equivalent to `ros2 topic echo --once/--times N`.

### `ros_read_scene`
Bundle a single top-down scene snapshot from up to 5 layers — occupancy grid map, pose, laser scan, planned path, pose array. The Android side auto-renders the result as a composed `SceneSnapshot` (map + base_link silhouette + scan dots + path + scale bar). Use for any *contextual* spatial question ("where am I", "show me the path on the map", "what does the robot see") instead of N separate `ros_read_topic` calls.

### `ros_topic_hz`
Rolling publish rate stats (avg/min/max/stddev) over `duration` seconds. Equivalent to `ros2 topic hz`.

### `ros_topic_bw`
Bandwidth estimate (bytes/sec and per-message sizes). Equivalent to `ros2 topic bw`.

### `ros_topic_delay`
Clock-skew between `header.stamp` and wall time. Requires stamped messages. Equivalent to `ros2 topic delay`.

### `ros_publish_topic` — **write**
Publish a message 1..N times, with server-side safety clamps for Twist linear/angular and JointTrajectory points (overridable via `SCRY_MAX_*` env vars and `SCRY_ALLOW_UNSAFE_PUBLISH=1`). Equivalent to `ros2 topic pub [--once|--times N] [-r rate]`.

---

## Service tools

### `ros_list_services`
List services (optionally with types). Equivalent to `ros2 service list -t`.

### `ros_find_services_by_type` · `ros_service_type` · `ros_service_info`
Discovery + introspection helpers — equivalents of `ros2 service find/type/info`.

### `ros_service_echo`
Observe service traffic via the introspection event topic. Requires rcl service introspection enabled on the server. Equivalent to `ros2 service echo`.

### `ros_call_service` — **write**
Send a synchronous service request. Equivalent to `ros2 service call`.

---

## Node tools

### `ros_list_nodes` · `ros_inspect_node`
Equivalents of `ros2 node list` and `ros2 node info`.

### `ros_list_nodes_with_resources`
List nodes joined with `ps`-derived CPU/memory data. Powers the Browse hub's Nodes tile when sorting by resource cost. Lives in the `process` toolset (not `nodes`), since it bridges the graph with OS-level resource data.

---

## Parameter tools

### `ros_list_parameters` · `ros_get_parameter` · `ros_describe_parameter` · `ros_dump_parameters`
Read-only inspection covering `ros2 param list/get/describe/dump`.

### `ros_set_parameter` — **write**
Set a single parameter. Equivalent to `ros2 param set`.

### `ros_load_parameters` — **write**
Apply a batch `{name: value, …}` to a node. Equivalent to `ros2 param load`.

### `ros_delete_parameter` — **write**
Delete a dynamically-declared parameter. Equivalent to `ros2 param delete`.

---

## Action tools

### `ros_list_actions` · `ros_action_type` · `ros_action_info`
Equivalents of `ros2 action list/type/info`.

### `ros_send_action_goal` — **write**
Send a goal, wait for the result, optionally capture feedback. Equivalent to `ros2 action send_goal [-f]`.

### `ros_cancel_action_goal` — **write**
Cancel an in-flight goal on an action server.

---

## Lifecycle tools

### `ros_lifecycle_nodes` · `ros_lifecycle_get` · `ros_lifecycle_list_transitions`
Discover lifecycle-enabled nodes, read their current states, list available transitions.

### `ros_lifecycle_set` — **write**
Trigger a transition. Valid: `configure`, `cleanup`, `activate`, `deactivate`, `shutdown`, `unconfigured_shutdown`, `inactive_shutdown`, `active_shutdown`.

---

## Package tools

### `ros_list_packages` · `ros_pkg_prefix` · `ros_pkg_executables` · `ros_pkg_launch_files` · `ros_pkg_xml`
Discover installed packages, their install prefixes, `lib/<pkg>` executables, the launch files a package ships, and `package.xml` contents.

### `ros_pkg_create` — **write**
Scaffold a new package on disk. Equivalent to `ros2 pkg create --build-type {ament_cmake,ament_python,cmake}`.

---

## Component tools

### `ros_component_list` · `ros_component_types`
Enumerate running containers and their loaded components; list every registered plugin class.

### `ros_component_load` · `ros_component_unload` · `ros_component_standalone` — **write**
Grow/shrink a running composition pipeline. `standalone` launches a throwaway container for smoke-testing and terminates after `timeout` seconds.

---

## ros2_control tools

Full 12-verb surface for the `controller_manager` framework. All target `/controller_manager` by default; pass `controller_manager` to point at another one.

### Read
- `ros_control_list_controllers` — per-controller state (`inactive`/`active`), types, claimed interfaces.
- `ros_control_list_controller_types` — all registered controller plugin classes.
- `ros_control_list_hardware_components` — hardware components with lifecycle state and R/W rate.
- `ros_control_list_hardware_interfaces` — command/state interfaces with `is_available`/`is_claimed`.
- `ros_control_view_controller_chains` — returns the chain topology as a Graphviz DOT string.

### Write (needs confirmation)
- `ros_control_load_controller` — load + optionally set state.
- `ros_control_unload_controller` — unload when `unconfigured`.
- `ros_control_set_controller_state` — set `inactive`/`active`.
- `ros_control_switch_controllers` — atomic activate/deactivate bundle (mode handover).
- `ros_control_reload_controller_libraries` — reload controller plugin .so's.
- `ros_control_cleanup_controller` — transition `inactive → unconfigured`.
- `ros_control_set_hardware_component_state` — drive hardware lifecycle.

---

## Daemon tools

### `ros_daemon_status` (read) · `ros_daemon_start` / `ros_daemon_stop` — **write**
Equivalents of `ros2 daemon status/start/stop`.

---

## Multicast tools

### `ros_multicast_receive` (read)
Listen on a multicast group for `duration` seconds. Useful when checking if DDS discovery packets reach this host.

### `ros_multicast_send` — **write**
Send one datagram. Tagged write because it emits network traffic.

---

## Doctor / WTF tools

### `ros_doctor`
Run `ros2 doctor` with all switches: `report`, `report_failed`, `include_warnings`, `exclude_packages`. Returns a diagnostic summary plus parsed warning/error lines and the return code; the full raw report is included (as a `report` field) only when `report=true` — it's omitted by default to avoid overflowing the model context.

### `ros_doctor_hello`
End-to-end DDS pub/sub round-trip check. Equivalent to `ros2 doctor hello`.

---

## Extensions

### `ros_extensions`
List registered `ros2cli` verbs. With `all=true`, returns a `{group: [verb, …]}` tree — essentially a live map of what the environment supports.

---

## Interface tools

### `ros_list_interfaces` · `ros_show_interface`
Equivalents of `ros2 interface list/show`.

---

## Bag tools

All bag operations are pinned under `$SCRY_BAG_ROOT` (default `~/ros2_bags`).

### `ros_bag_info` · `ros_bag_list` · `ros_bag_record_status`
Inspect a single bag directory, list the bags found under the bag root, and check whether a recording is currently in progress. Read-only.

### `ros_bag_record_start` · `ros_bag_record_stop` — **write**
Start or stop a `ros2 bag record` session against a chosen set of topics. Tagged write because recording spawns a process and writes to disk. Playback is deferred.

---

## DDS / environment tools

### `ros_get_dds_info`
High-level summary: distro, middleware, domain id, localhost-only flag, discovery range, hostname.

### `ros_get_dds_env`
Full env var dump. Pass `group=` to narrow to one of: `discovery`, `rmw`, `network`, `zenoh`, `logging`, `distro`.

Covered variables:

| Group | Variables |
|-------|-----------|
| discovery | `ROS_DOMAIN_ID`, `ROS_LOCALHOST_ONLY`, `ROS_AUTOMATIC_DISCOVERY_RANGE` |
| rmw | `RMW_IMPLEMENTATION`, `FASTRTPS_DEFAULT_PROFILES_FILE`, `FASTDDS_DEFAULT_PROFILES_FILE`, `CYCLONEDDS_URI` |
| network | `ROS_IP`, `ROS_HOSTNAME` |
| zenoh | `ZENOH_ROUTER_CONFIG_URI`, `RMW_ZENOH_CONFIG_FILE`, `RMW_ZENOH_SESSION_CONFIG_URI` |
| logging | `RCUTILS_LOGGING_SEVERITY_THRESHOLD`, `RCUTILS_COLORIZED_OUTPUT`, `RCUTILS_CONSOLE_OUTPUT_FORMAT`, `ROS_DISABLE_LOANED_MESSAGES` |
| distro | `ROS_DISTRO`, `ROS_VERSION`, `ROS_PYTHON_VERSION`, `AMENT_PREFIX_PATH` |

### `ros_network_interfaces`
Enumerate IPv4/IPv6 addresses on every interface — primary DDS discovery triage tool.

---

## Diagnostics tools

### `ros_get_diagnostics` · `ros_check_health` · `ros_get_recent_logs` · `ros_liveness` · `ros_graph_diff`
Read the latest `/diagnostics`, roll up a one-shot health summary, tail `/rosout` with filters, grab a cheap heartbeat (`ros_liveness` — `/tf`, `/clock`, `/rosout` error counts, node-churn over 5 min; safe to poll once a second), or snapshot the ROS graph and report what changed since the last snapshot (`ros_graph_diff` — added/removed nodes, topics, and services).

`ros_check_health` is the **single MCP call the Android dashboard makes** to populate its Graph / Liveness / Diagnostics sections, so its return shape is wider than the name suggests. Fields:

| Field | Type | Source |
|---|---|---|
| `nodes_up` | int | rclpy graph |
| `topics_active` | int | rclpy graph |
| `services_available` | int | rclpy graph |
| `actions_active` | int | derived from hidden `/_action/` topic markers |
| `lifecycle_nodes_total` | int | service graph (`*/get_state`) |
| `last_rosout_seen_s` | float \| null | one short subscribe to `/rosout` (1 s timeout) |
| `last_diagnostics_seen_s` | float \| null | piggyback of the existing `/diagnostics` read |
| `diagnostics_total` | int | length of the latest `/diagnostics` aggregate |
| `diagnostics_summary` | object | `{OK, WARN, ERROR, STALE, UNKNOWN}` counts |
| `warnings`, `errors` | list[str] | legacy, kept for AI-prose summarisation |
| `timestamp` | float | wall clock when the connect produced the snapshot |

`null` values are honest: a `last_rosout_seen_s` of null means *no message arrived during the read window*, not *the topic doesn't exist*. The Android dashboard renders this as "no message in window" and lets the developer interpret it.

The call is designed to stay under ~1.5 s by piggybacking last-seen timestamps on cheap rclpy graph queries plus two short reads (`/rosout` and `/diagnostics`), each capped at a 1-second timeout.

---

## TF tools

### `ros_tf_frames`
List every TF frame currently known, with its parent, broadcaster, and publish rate. Analogous to `ros2 run tf2_tools view_frames` (no PDF). Powers the Browse hub's TF tile and is auto-rendered as a `Tree` block in chat with per-edge rate badges.

### `ros_tf_lookup`
Look up the latest transform from `source_frame` to `target_frame`. Equivalent to one shot of `tf2_echo`. Auto-rendered as an `EntityCard` (translation + rotation sections).

---

## Watcher tools

Long-running observers, up to 60 s each.

- `ros_watch_topic(topic, duration, condition?, max_events)` — subscribes, optionally stops early when a `condition` like `pose.x > 5` matches. Returns sequence of messages with timestamps; auto-rendered as a `LineChart` when fields are scalar.
- `ros_watch_diagnostics(duration, level_filter?)` — captures `/diagnostics` with level filtering.
- `ros_watch_node(node, duration, poll_interval)` — detects appearance / disappearance (crash / restart).
- `ros_wait_for_topic(topic, timeout)` — blocks until a topic appears (bringup debugging).

Condition expressions are evaluated safely — only dotted field paths and comparison operators are allowed, never arbitrary code.

---

## Process tools

The connect tracks every process it launches and can also enumerate any
ROS-related process on the host.

### Read
- `ros_list_processes` — every background process the connect launched (pid, uptime, return code if exited).
- `ros_list_system_processes` — system-wide `ps` view filtered to ROS-related commands, cross-referenced against connect-launched IDs. Powers the Browse hub's Processes tile.
- `ros_system_processes` — same as `ros_list_system_processes` with a finer-grained sort/filter surface. The two coexist; consolidating is a follow-up.
- `ros_tail_process` — last N lines of stdout for a connect-launched process.

### Write
- `ros_run_node`, `ros_run_launch`, `ros_run_script` — spawn an `ros2 run` / `ros2 launch` / `python` process in the background, tracked. Identifiers validated against `_validate_ident` (lowercase alnum + underscore, ≤64); launch args whitelisted by `_LAUNCH_ARG_RE` / `_ROS_FLAG_RE`.
- `ros_restart_launched` — restart a previously-launched process.
- `ros_kill_process` — TERM (or KILL) a tracked background process.

---

## Build tools

Scratch files, workspaces, and file export all live in the `build` area.

### Read
- `ros_list_scratch_files` — enumerate the scratch files dropped under `/tmp/scry-scratch/<session>/` (Python relay node, ad-hoc launch, YAML snippet) so a subsequent `ros_run_*` can use them.
- `ros_list_workspaces` — list colcon workspaces the connect can detect. Auto-discovery uses `$SCRY_BUILD_WORKSPACES` (override), `$COLCON_PREFIX_PATH`, and the usual install conventions.
- `ros_export_file` — read a file from one of the connect's allowed roots (the bag root, scratch dir, and any path in `$SCRY_EXPORT_ROOTS`) so the phone can download it. Confined to those roots — it can't read arbitrary paths.

### Write
- `ros_write_scratch_file` — create / overwrite a scratch file.
- `ros_colcon_build` — run `colcon build --packages-select <pkg…>` in a workspace. The package list is required — Scry must name exactly what it's building.

---

## System tools

### `ros_system_info`
Host system snapshot — OS / kernel / CPU / memory / disk / GPU. One call powers the dashboard's System card (cheap, ~50–150 ms).

---

## Behaviour-tree tools

For Nav2 / BehaviorTree.CPP integrations.

- `ros_bt_list_sources` — discover every navigator on the graph and the BT XMLs it exposes via param.
- `ros_bt_get_active_tree` — fetch the active Nav2 BT XML (via `/bt_navigator`'s `default_nav_to_pose_bt_xml` param), parse it, and return a flat node list (`{root_uid, nodes:[{uid, tag, name, kind, children, attrs}]}`). Auto-rendered as a `BtTreeView` block (kind-coloured nodes, status-coloured borders) — same canvas used by the Viz tab's BT section.
- `ros_bt_status` — subscribe to `/behavior_tree_log` briefly and return the latest status (IDLE / RUNNING / SUCCESS / FAILURE) per node UID, plus how recently each was reported.

---

## Teleop tools

All three are write-gated — they emit Twist commands.

- `ros_teleop_start(topic, rate_hz)` — open a persistent Twist publisher at `rate_hz`. Cheap setup tax — call once when the user opens the teleop view.
- `ros_teleop_set(linear, angular)` — update the latched Twist value.
- `ros_teleop_stop()` — close the publisher.

The Twist values are clamped by the same `safety.SafetyPolicy` envelope as `ros_publish_topic`.

---

## Docker tools

Useful when the robot runs Nav2 / drivers in containers.

- `ros_docker_status` — aggregate snapshot: daemon availability, version, container list, per-running-container live stats (CPU %, mem, IO).
- `ros_docker_inspect` — `docker inspect` for one container.
- `ros_docker_logs` — last N lines from a container's stdout.

---

## Host shell tools

Running a shell command on the robot is the one capability that's **off
by default**. In the connect's default open mode the shell tools are
disabled outright; they only become available when the operator starts
the connect with `--allow-open-exec` (or runs in token / mTLS mode).
Even then, every command still pauses for your tap-to-approve on the
phone, exactly like any other action — and writes are recorded in the
audit log when one is configured. This is a deliberate trade-off: it's
the highest-blast-radius capability Scry has, so it's gated more tightly
than anything else.

### Read
- `ros_shell_read` — run a read-only command and return its output.
- `ros_query_shell_job` · `ros_list_shell_jobs` — check on, and list, long-running shell jobs the connect launched.

### Write (needs confirmation, and `--allow-open-exec`)
- `ros_shell_exec` — run a shell command on the host.
- `ros_kill_shell_job` — terminate a tracked shell job.

---

## Incident tools

A small on-robot store of solved problems, so Scry can recognise an
issue it (or you) has diagnosed before and recall the fix.

### Read
- `ros_search_incidents` — search past incidents by symptom.
- `ros_get_incident` — fetch one incident's full record.

### Write
- `ros_save_incident` — record a new incident and its resolution.

---

## MCP resources

In addition to tools, the connect exposes read-only resources:

| URI | Description |
|-----|-------------|
| `ros://system/info` | ROS distro, hostname, domain ID, middleware, uptime |
| `ros://topics/{name}/schema` | Message type definition for a topic |
| `ros://nodes/{name}/info` | Node introspection (publishers, subscribers, services) — recomputed live from the ROS graph on each read |

---

## Why reads and actions are split

Two ideas shape the list above:

1. **Safe by default.** Scry can freely inspect anything — topics,
   bandwidth, diagnostics, logs, controller chains, behaviour trees,
   scenes. None of it changes how the robot behaves.
2. **Explicit consent to act.** Anything that publishes a message,
   drives a controller, changes a parameter, writes a file, or launches
   a process pauses for your approval on the phone first (and, in token
   mode, an extra one-time approval code).

## What Scry adds on the phone

Beyond what the robot exposes, Scry has a few capabilities that run
entirely on your phone — they never go to the robot:

| Capability | What it does |
|---|---|
| Live panels | Embed a short live sensor / plot / scene / camera panel right in the chat |
| Live scene | Combine a map, pose, laser scan, and path into one live view |
| Plans | Render a multi-step diagnostic checklist with a verdict |
| Background monitors | Watch a topic field in the background and alert you when a threshold trips (see [Background monitors](../use/monitors.md)) |
| Fleet overview | Ping every saved robot and show a per-robot status card |
| Fleet query & diff | Ask one question across your whole fleet, or diff which topics each robot is running |
| Fleet health snapshot | Roll up a one-shot health summary for every saved robot at once |
| Robot comparison | Put two robots side by side on the metrics you choose |
| Parallel sub-agents | For a big question, fan out up to four read-only helpers in parallel and merge what they find (any fix is still proposed for your approval) |
