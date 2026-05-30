# Scry Security Audit

**Date:** 2026-04-24
**Last remediation pass:** 2026-04-24
**Scope:** `android/`, `scry-connect/`, `robot-setup/`
**Posture:** Phase 0/1 Alpha. LAN-only threat model per `CLAUDE.md`. Alpha release not yet distributed.

---

## 0. Remediation Status

The original audit and the status of each finding after the 2026-04-24
hardening pass. Every **C-** and **H-** item is addressed; the auth model
was then re-tuned 2026-04-24 (later that day) to align with rosbridge /
foxglove_bridge conventions — open by default, opt-in to stricter modes.

### Posture change (2026-04-24, second pass)

Mandatory auth was friction in practice (users had to SSH into the robot
to copy a token before they could debug). After comparing to rosbridge,
foxglove_bridge, and rmw_zenoh, we flipped the default to **open** and
made hardening opt-in. The connect stays safe in open mode because:

1. RFC1918 / loopback gate rejects callers from public IPs by default.
2. Phone-side approval dialog is the human-in-the-loop for writes.
3. Safety envelope caps velocity / effort / rate magnitudes server-side.
4. Audit log captures every write attempt with source IP.
5. Optional deadman switch makes write authority track the phone screen.

Token mode is one CLI flag (`--token`) and pairs via QR from the phone.
mTLS is `--mtls`.

| ID | Title | Status |
|----|-------|--------|
| C-1 | Unauthenticated MCP endpoint | **Re-scoped.** Default is open mode with an RFC1918 / loopback gate (`security.is_local_or_rfc1918`). Token (`--token`, paired via QR) and mTLS (`--mtls`) modes are opt-in. Public-internet open mode requires explicit `--public-internet`. |
| C-2 | Client-side-only write gate | **Fixed in token / mtls modes.** `server.call_tool` rejects write tools without a one-shot `X-Scry-Confirm` nonce when auth ≠ open. Android mints the nonce in `AiProxyLoop.run` after user approval; `McpClient.issueConfirmation` does the exchange. In open mode the phone approval dialog is the gate; demanding a server nonce there is theatre because a LAN attacker can DDS-publish directly. |
| C-3 | Docker dev stack exposes host X server | **Fixed.** `docker-compose.dev.yml` defaults `turtlesim` to `QT_QPA_PLATFORM=offscreen` and no longer mounts `/tmp/.X11-unix` / `XAUTHORITY`. GUI mode moved to opt-in `docker-compose.gui.yml` override. |
| H-1 | No ROS safety bounds on write tools | **Fixed.** `safety.SafetyPolicy` + `safety.check_publish` clamp Twist linear/angular, JointTrajectory points, publish rate, and publish count. `TopicManager.pub` enforces it. Overridable via `SCRY_MAX_*` env vars and `SCRY_ALLOW_UNSAFE_PUBLISH=1`. |
| H-2 | Unbounded regex on AI `filter` args | **Fixed.** `managers.safe_filter` compiles with a 256-char cap, catches `re.error`, and routes star/question-mark patterns through `fnmatch` which cannot backtrack. Applied in `topic.py`, `service.py`, `action.py`, `param.py`, `pkg.py`, `interface.py`. |
| H-3 | `ros_bag_info` accepts arbitrary paths | **Fixed.** `bag.BagManager._resolve_under_root` pins paths under `$SCRY_BAG_ROOT` (default `~/ros2_bags`) with `Path.resolve + relative_to`. |
| H-4 | OkHttp logging interceptor always on | **Fixed.** `di.AppModule.provideOkHttpClient` only attaches `HttpLoggingInterceptor` when `BuildConfig.DEBUG`. |
| H-5 | `ROS_DOMAIN_ID=0` + host networking | **Partially fixed.** Dev compose now defaults to `ROS_DOMAIN_ID=42` with a commented `ROS_LOCALHOST_ONLY=1` toggle and a prominent warning. Production operators still choose their own domain. |
| M-1 | `ros_run_node` / `ros_run_launch` unchecked identifiers | **Fixed.** `process._validate_ident` (lowercase alnum + underscore, length ≤64) plus `_LAUNCH_ARG_RE`/`_ROS_FLAG_RE` whitelist for args. |
| M-2 | Room DB unencrypted | **Documented** in SECURITY.md. No change to the DB layer; Phase 0 accepts plaintext at rest. |
| M-3 | `fallbackToDestructiveMigration` | **Documented.** Acceptable for alpha; flag in release checklist. |
| M-4 | Raw exception messages leak | **Fixed.** `server.call_tool` returns `ManagerError` details verbatim (expected surface) but maps everything else to `{"error": "internal_error", "error_id": "..."}` and logs the traceback server-side. |
| M-5 | `_build_condition` attribute traversal defensive note | **Unchanged.** Still only reached via `msg_to_dict`'d records per `watcher.py:81`. Added to SECURITY.md as a maintained invariant. |
| M-6 | `MainActivity` launchMode | **Fixed.** `android:launchMode="singleTask"` added to `AndroidManifest.xml`. |
| M-7 | Singleton OkHttp across cloud + LAN | **Documented** — NSC already denies cleartext to current AI hosts. Adding a new cloud provider is a reviewable diff because `network_security_config.xml` is also touched. |
| L-1..L-8 | Tracked in the body; none block alpha. |  |
| I-10 | No SECURITY.md / threat model | **Fixed.** `SECURITY.md` at repo root, referenced from README. |

**Blocker list verdict:** all C-tier and H-tier items closed in code.
Medium items are either fixed, documented with explicit trade-offs, or
deferred to the release checklist.

---

## 1. Executive Summary

Scry is a phone-proxied AI robot controller. The Android app is reasonably well-built for an alpha (EncryptedSharedPreferences for BYOK keys, write-tool confirmation in the proxy loop, narrow `networkSecurityConfig`). The **connect, by contrast, is unauthenticated** and executes every tool — including hardware-control writes — that reaches `/mcp/`. The entire "write operations require user confirmation" guarantee documented in `CLAUDE.md` lives exclusively on the Android client; any process on the LAN can bypass it.

The top risks, in order:

1. **C-1 Unauthenticated MCP endpoint executes write tools.** `scry-connect/scry_connect/server.py:48-77` — no auth middleware, no confirmation header check, `is_write_tool()` never consulted.
2. **C-2 Write-gate parity is a client-side honor system.** `android/.../domain/usecase/McpToolCatalog.kt:44` vs `scry-connect/.../tools/registry.py` — enforced only by `WriteToolParityTest`. Nothing prevents a rogue MCP caller from invoking `ros_publish_topic` on `/cmd_vel` with arbitrary values.
3. **H-1 `docker-compose.dev.yml` binds the connect on `0.0.0.0` with host networking** while simultaneously mounting `XAUTHORITY` and `/tmp/.X11-unix` for the `turtlesim` service. A LAN peer can drive the robot and (on the dev host) reach the X server.
4. **H-2 No ROS safety bounds on write tools.** `ros_publish_topic` accepts any `data` dict (`managers/topic.py:240`); no velocity/acceleration clamps on `cmd_vel`-shaped topics. If the AI hallucinates or an attacker owns the connect, physical damage is possible.
5. **H-3 Topic-name and regex-filter inputs are unvalidated.** `filter` parameters across tools are fed directly to `re.search` (`managers/topic.py:56`, `managers/param.py:28`, others) — catastrophic-backtracking regexes produced by the AI can freeze handlers inside the shared rate-limited event loop.

Nothing is immediately exploitable from the cloud (no public endpoints, no secrets in repo). Risk is entirely on the **LAN trust boundary**, which is explicitly accepted in `cli.py:24` help text but has **not** been surfaced to end users in README/install.sh.

---

## 2. Critical Findings

### C-1 — Connect HTTP endpoint is fully unauthenticated

- **Severity:** Critical
- **Component:** Scry Connect
- **Files:** `scry-connect/scry_connect/server.py:48-77`, `scry-connect/scry_connect/cli.py:22-24`, `robot-setup/docker-compose.dev.yml:48`
- **Description:** The Starlette app mounts `/mcp` with no auth middleware. `call_tool` dispatches any registered tool, including the 31 write-gated ones, without checking `is_write_tool()` or any caller identity. The CLI's `--public` flag binds `0.0.0.0:5339` and the dev compose file hardcodes `--host 0.0.0.0` with `network_mode: host`.
- **Impact:** Any device on the same WiFi/LAN (including guest networks, coffee-shop APs, compromised IoT) can list tools and invoke `ros_publish_topic`, `ros_call_service`, `ros_send_action_goal`, `ros_run_node`, `ros_set_parameter`, `ros_lifecycle_set`, `ros_control_switch_controllers`, etc. On a real robot this is direct physical control.
- **Remediation:**
  1. Require a shared secret header (`X-Scry-Token`) on `/mcp` and `/stream`. Generate on first launch, write to `~/.config/scry/token`, display as QR for the app to scan.
  2. Add a Starlette middleware that rejects requests lacking the token with 401. Default-deny.
  3. Have `call_tool` additionally require an `X-Scry-Confirm: <tool-use-id>` header for any tool where `is_write_tool(name)` is true. The Android app must echo the approved tool-use id.
  4. Change `cli.py` default to `127.0.0.1`, make `--public` require either `--token` or `--insecure-no-auth` to choose explicitly.

### C-2 — Write-gate / confirmation flow is client-side only

- **Severity:** Critical
- **Component:** Cross-component (Android ↔ Connect trust boundary)
- **Files:** `android/app/src/main/java/com/scry/domain/usecase/AiProxyLoop.kt:150-204`, `android/.../McpToolCatalog.kt:44-73`, `scry-connect/scry_connect/server.py:48-77`, `scry-connect/scry_connect/tools/registry.py` (write-gate flags are distributed across the `_add(..., write=True)` calls, not a single block)
- **Description:** `AiProxyLoop.run` splits pending tool calls into reads (parallel) and writes (await user approval). The connect's `call_tool` has no equivalent gate — it calls `reg.handler(arguments)` regardless of `reg.write`. The two write sets can drift; parity is guarded only by `android/app/src/test/java/com/scry/domain/usecase/WriteToolParityTest.kt`.
- **Impact:** Defeats the central safety claim in `CLAUDE.md` ("All write operations require user confirmation"). An attacker (or a local command-line curl) bypasses the phone entirely.
- **Remediation:** Pair C-1 token auth with a server-side write-gate: the Android approval UI issues a one-shot confirmation token per tool use id, included as a request header. `call_tool` rejects any write tool whose token is missing/used/unexpired. Keep `WriteToolParityTest` but make it verify the server-side set, not the client-side mirror.

### C-3 — Docker dev stack exposes host X server alongside unauthenticated connect

- **Severity:** Critical (dev-only, but will be pattern-copied)
- **Component:** robot-setup
- **Files:** `robot-setup/docker-compose.dev.yml:82-84`
- **Description:** `turtlesim` mounts `/tmp/.X11-unix` and `$XAUTHORITY` into a container that shares `network_mode: host`. Combined with the unauthenticated `:5339` endpoint in the same compose file, a LAN peer who exploits anything inside the container (or who controls the connect via C-1) reaches the developer's X display.
- **Impact:** Dev-machine compromise beyond the ROS surface — keystrokes, screen capture, arbitrary X input.
- **Remediation:** Default `QT_QPA_PLATFORM: offscreen` (the commented branch) and remove the X11 mounts from the default. Move GUI mode behind an opt-in `docker-compose.gui.yml` override with a prominent README warning.

---

## 3. High Findings

### H-1 — No velocity / bound checks on robot-control publishes

- **Files:** `scry-connect/scry_connect/managers/topic.py:240-263`, `scry-connect/scry_connect/tools/registry.py:163-176`
- **Description:** `ros_publish_topic` accepts any `data` dict and any `times`/`rate_hz` within `[1..1000]`. For `geometry_msgs/Twist` on `/cmd_vel` this means the AI can publish arbitrary linear/angular velocities at 1 kHz. There is no per-topic safety validator, no velocity clamp, no emergency-stop interlock.
- **Impact:** A hallucinated tool call (or a C-1-abusing attacker) can drive a real robot into walls or people. ROS 2 has no middleware-layer throttle.
- **Remediation:**
  1. Add a configurable safety policy (`config.py`) per-topic type: max linear/angular velocity, max effort, max joint-trajectory step. Reject publishes that exceed it server-side with a clear error.
  2. Require an explicit opt-in (`SCRY_ALLOW_UNSAFE_PUBLISH=1`) for tele-op use cases.
  3. Consider always inserting a deadman topic `scry/enable` that the Android app must publish at ≥2 Hz; the connect drops writes when stale.

### H-2 — Unbounded regex on AI-controlled `filter` args (ReDoS)

- **Files:** `scry-connect/scry_connect/managers/topic.py:56`, `managers/param.py:28`, `managers/service.py`, `managers/action.py`, `managers/pkg.py:28`, `managers/interface.py`
- **Description:** `filter` args are passed directly to `re.search(filter_pattern, name)`. The AI model emits these; nothing prevents a pathological pattern like `(a+)+$`. One bad filter synchronously blocks the asyncio event loop handling every other MCP request.
- **Impact:** Single-tool DoS hangs the connect (rate-limited tokens accumulate but handlers can't run).
- **Remediation:** Compile with `re.compile(pattern)` inside a `try/except re.error`; reject patterns longer than N chars; run the match inside `asyncio.to_thread` with a short timeout; or prefer `fnmatch`-style globs for these filters.

### H-3 — `ros_bag_info` accepts arbitrary paths

- **Files:** `scry-connect/scry_connect/managers/bag.py:15-17`, `tools/registry.py:681-684`
- **Description:** `ros_bag_info` passes the user/AI-provided `path` straight to `ros2 bag info <path>` with no allowlist. While there is no shell interpolation (arg list subprocess), the CLI will read whatever file path it's given and expose metadata about it in the response.
- **Impact:** Information leak of bag file locations on the robot. Not RCE, but lets an attacker enumerate the filesystem for bag targets.
- **Remediation:** Constrain to a configurable root (e.g. `~/ros2_bags`) similar to the pattern in `pkg.py:92-98`, or require a relative path + resolve under an allowed directory.

### H-4 — OkHttp logging interceptor at BASIC level in all builds

- **Files:** `android/app/src/main/java/com/scry/di/AppModule.kt:51`
- **Description:** `HttpLoggingInterceptor(BASIC)` is installed unconditionally (no `if (BuildConfig.DEBUG)`). BASIC only logs method/url/status, but still leaks robot LAN IPs and Ollama URLs on release-build logs readable via `adb logcat` on the user's device and any crash collector.
- **Impact:** Low in isolation but becomes High if someone upgrades the level, or pairs with a log-exfil vulnerability.
- **Remediation:** Wrap with `if (BuildConfig.DEBUG) builder.addInterceptor(logging)`.

### H-5 — Dev compose pins `ROS_DOMAIN_ID: "0"` on host networking

- **Files:** `robot-setup/docker-compose.dev.yml:26-27`
- **Description:** Domain 0 + host networking + default CycloneDDS/FastRTPS behavior means the connect participates in every ROS 2 graph on the LAN. Combined with C-1, any ROS 2 node on the network is visible and reachable.
- **Remediation:** Document the default, encourage `ROS_DOMAIN_ID` > 0 and `ROS_LOCALHOST_ONLY=1` for single-machine development.

---

## 4. Medium Findings

### M-1 — `ros_run_node` / `ros_run_launch` accept any package/executable name

- **Files:** `scry-connect/scry_connect/managers/process.py:57-88`
- **Description:** `package` and `executable` go straight into `asyncio.create_subprocess_exec(["ros2", "run", package, executable, …])`. No shell, so no injection, but also no validation that the names are legitimate ROS package identifiers. Combined with C-1 an attacker can spawn up to 20 concurrent processes (`MAX_PROCESSES = 20`).
- **Remediation:** Validate `package`/`executable` against the same regex used in `pkg.py` (`[a-z][a-z0-9_]{1,63}`) before exec.

### M-2 — Room DB is not encrypted; chat history persisted

- **Files:** `android/app/src/main/java/com/scry/di/AppModule.kt:26-29`, `android/.../data/local/ScryDatabase.kt`
- **Description:** Standard Room (unencrypted SQLite). Chat history (which may contain robot internal state) and saved-robot hosts/ports are stored in plaintext. Acceptable for a debugging tool but worth noting.
- **Remediation:** Optional — SQLCipher/Jetpack Security EncryptedFile if sensitive operational data is expected. At minimum: document that chat history is unencrypted at rest so users don't paste secrets.

### M-3 — `fallbackToDestructiveMigration()` enabled

- **Files:** `android/.../di/AppModule.kt:28`
- **Description:** Silent schema wipes on every migration failure. Fine for alpha; flag before release.

### M-4 — Connect exception messages propagate raw to client

- **Files:** `scry-connect/scry_connect/server.py:72-77`
- **Description:** `return {"error": str(e), "tool": name}` returns raw exception text including file paths, parameter internals, rclpy stack context. Pairs with C-1 to aid reconnaissance.
- **Remediation:** For non-`ManagerError` exceptions, return a generic "internal error" and log details server-side. Keep the specific `InvalidArgument`/`NotFound`/`Timeout` messages since they are expected.

### M-5 — Condition expression `_build_condition` parser permits arbitrary attribute traversal

- **Files:** `scry-connect/scry_connect/managers/watcher.py:317-324`
- **Description:** `_resolve_path` uses `getattr(cur, p)` when `cur` is not a dict. Because watcher callbacks receive ROS msg objects before they're dict-converted… actually `matcher` is called on the already `msg_to_dict`-encoded `record["data"]` (line 81), so this is safe. Flagging defensively: if future refactors pass raw ROS messages the `getattr` branch becomes an introspection primitive against arbitrary Python objects.
- **Remediation:** Harden `_resolve_path` to dict-only now, before the invariant is forgotten.

### M-6 — `MainActivity` is `exported="true"` with no deep-link intent filter beyond LAUNCHER

- **Files:** `android/app/src/main/AndroidManifest.xml:39`
- **Description:** Standard for a launcher activity, but the manifest does not set `android:launchMode` and `ChatViewModel` accepts user input immediately on foreground. No current intent-based attack surface but worth keeping narrow — `exported="true"` is necessary for LAUNCHER only, not for any deep-link/view intents that may be added later.
- **Remediation:** Add `android:launchMode="singleTask"` and keep the intent filter list minimal.

### M-7 — Hilt `@Singleton OkHttpClient` shared across robot and cloud AI calls

- **Files:** `android/.../di/AppModule.kt:49-57`
- **Description:** One client for both plaintext robot-LAN traffic and TLS calls to `api.anthropic.com`. NetworkSecurityConfig prevents cleartext to the named domains, so TLS is enforced, but if a new AI provider is added without updating `network_security_config.xml` it silently inherits cleartext allowance.
- **Remediation:** Either (a) flip the NSC default to `cleartextTrafficPermitted="false"` and explicitly whitelist RFC1918 via per-IP `domain-config` blocks where possible, or (b) add a lint/test that every `AiClient` URL host is present in NSC.

---

## 5. Low Findings

### L-1 — `install.sh` uses `curl | bash` pattern
- **Files:** `robot-setup/install.sh:5`, README. Industry-standard but opaque. Document the SHA256 of the script, or prefer a pip-only install path.

### L-2 — `RECORD_AUDIO` and `CAMERA` permissions declared at manifest level (`AndroidManifest.xml:7-8`). Justified (voice input, image attach) but should be requested at runtime, which the code does through `TapToTalkMic.kt` — verify runtime consent still shown before first use.

### L-3 — `lastActiveRobotId` is stored in encrypted prefs (`SecurePrefs.kt:84-86`) though it's not sensitive. Harmless; just notes that the encryption overhead is non-zero per-read for a value that could live in plain prefs.

### L-4 — `network_security_config.xml` allowlist covers only Claude, OpenAI, Gemini. Ollama is cleartext by design (LAN) but any future cloud provider (Groq, xAI, etc.) will silently fall through to the cleartext-allowed base config.

### L-5 — No PII scrubbing on chat logs sent to AI providers. A user typing a hostname, IP, or robot serial goes straight to Anthropic/OpenAI. Document in privacy notice.

### L-6 — SSE topic stream (`streaming/sse.py`) inherits the same no-auth posture as `/mcp`. Read-only, but exposes live sensor data to LAN peers. Subsumed by C-1 remediation.

### L-7 — `Dockerfile.dev` is not audited here (not read); ensure it does not install packages as root without pinning.

### L-8 — `scry-connect.service` (systemd) uses `Restart=on-failure` with no `User=`/`Group=` — service runs as the invoking user, which is typical but should be documented. Explicitly reject running as root.

---

## 6. Info

- **I-1 Positive:** `SecurePrefs.kt` uses `EncryptedSharedPreferences` (AES256-GCM) with proper `backup_rules.xml` / `data_extraction_rules.xml` exclusions. Good.
- **I-2 Positive:** `network_security_config.xml` explicitly forbids cleartext to cloud AI providers — correct defense-in-depth.
- **I-3 Positive:** `shell_runner.py` consistently uses arg-list `create_subprocess_exec`, never `shell=True`. Grep confirms no `shell=True` / `os.system` / `eval` / `pickle.loads` / `yaml.load` anywhere.
- **I-4 Positive:** `pkg.py:91-98` correctly validates `destination_directory` against `$HOME` via `os.path.realpath` — good path-traversal defense.
- **I-5 Positive:** `PkgManager.create` regex-validates package names, node names, and dependency names against strict identifiers.
- **I-6 Positive:** `isMinifyEnabled = true` and `isShrinkResources = true` for release (`android/app/build.gradle.kts:27-28`).
- **I-7 Positive:** `allowBackup="false"` and `debuggable` not forced (`AndroidManifest.xml:26`).
- **I-8 Positive:** Watcher expressions avoid `eval` — parsed manually by `_build_condition`. Good.
- **I-9 Positive:** Rate limiter (`rate_limiter.py`) guards against runaway AI loops.
- **I-10 Gap:** No `SECURITY.md`, no documented threat model, no vulnerability-disclosure contact.

---

## 7. Defense-in-Depth Recommendations

1. **Server-side write-gate.** Even after C-1 token auth lands, keep a server-enforced `is_write_tool()` check with a distinct confirmation nonce. Never trust the phone alone.
2. **Typed safety envelope for publishes.** Encode per-message-type max magnitudes (Twist, JointTrajectory, JointCommand) in a YAML config loaded at connect start. Reject out-of-envelope values with a structured `SafetyViolation` error surfaced in the Android approval dialog.
3. **Audit log.** Append every write-tool invocation (tool, args, caller, timestamp, success) to `~/.local/state/scry/audit.jsonl` for post-incident review.
4. **Deadman switch.** Android publishes a `/scry/enable` bool at 2 Hz while the chat is active; connect drops write tools if the latch is stale >1 s.
5. **mTLS option.** For production deployments, offer a `--cert`/`--key` flag pair. Ship a `scry-connect gen-cert` helper that outputs a self-signed cert + the fingerprint for the app to pin.
6. **SROS2 documentation.** The current architecture sidesteps DDS security entirely. Document when users should enable SROS2 and what it buys them vs scry token auth.
7. **Per-IP allowlist on connect.** `--allow 192.168.1.0/24` flag for users who want LAN-scoped but not promiscuous.
8. **Dependency scanning in CI.** Add `pip-audit` on `scry-connect` and `./gradlew dependencyCheckAnalyze` (OWASP) on the app. No CVEs were identifiable from pyproject/gradle versions at audit time, but `mcp>=1.0.0` / `starlette>=0.36.0` are unpinned floors.
9. **Clarify trust boundary in README.** `cli.py:24` warns "do not use on shared networks" but `README.md` and `install.sh` do not. Users read those first.
10. **Android release signing checklist.** Not yet present — add before Play-store upload.

---

## 8. Pre-Deployment Checklist (BLOCKERS)

Before **any** deployment outside the author's single-host dev loop:

- [ ] **C-1** Connect requires a shared token for `/mcp` and `/stream`; default bind is `127.0.0.1`; `--public` requires `--token`.
- [ ] **C-2** `call_tool` enforces `is_write_tool()` with a per-invocation confirmation nonce issued by the Android approval UI.
- [ ] **C-3** Dev `docker-compose.dev.yml` defaults to `QT_QPA_PLATFORM=offscreen`; GUI mode moved to an opt-in override file.
- [ ] **H-1** Per-topic-type safety envelope in connect config; `ros_publish_topic` rejects out-of-bounds messages. Document the default envelope for `geometry_msgs/Twist`.
- [ ] **H-2** `filter` regex args compiled with length cap + `re.error` handling; matches run off the event loop or use a glob.
- [ ] **H-3** `ros_bag_info` path constrained to a configured bag root.
- [ ] **H-4** `HttpLoggingInterceptor` wrapped in `BuildConfig.DEBUG`.
- [ ] **M-1** `ros_run_node` / `ros_run_launch` validate package/executable identifiers.
- [ ] **M-4** Generic error envelope for unexpected exceptions in `server.call_tool`.
- [ ] **README / install.sh** surface the LAN trust assumption and token setup steps prominently.
- [ ] Add `SECURITY.md` with disclosure contact.
- [ ] CI gates: `pip-audit` for connect, `./gradlew test lint` for Android, `WriteToolParityTest` must pass.
- [ ] Release APK signed with v2+v3 signature, `isDebuggable` explicitly `false` for release (currently relies on default — add an assertion).

---
*End of audit.*
