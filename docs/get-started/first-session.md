# First debugging session

Phone is paired with the robot. Time to actually use Scry. Five things
to try, in order — each one demos a different capability.

## 1. "What's my robot's health?"

In the chat composer at the bottom of the Scry tab, type:

```
What's my robot's health?
```

Tap **Send**. The agent will:

1. Call the `robot_health` MCP tool on the connect
2. Get back a structured snapshot: nodes alive, topics publishing,
   battery if available, ROS_DOMAIN_ID, transient errors
3. Render an inline health card (the green/yellow boxes)
4. Add a short text conclusion above the card

Total time: 1–3 seconds. The data is **live** — every call hits your
robot, no caching.

## 2. "What topics are publishing?"

```
What topics are publishing right now?
```

The agent calls `ros_topic_list` and renders a table with each topic's
name, type, and publish rate (where measurable). Tap a topic to drill
into details.

## 3. Inspect a single topic

```
What's on /odom?
```

If `/odom` exists on your robot, the agent calls `ros_topic_echo` for
one message and renders the JSON inline. For high-frequency topics
(IMU, camera, lidar) it instead calls `ros_topic_hz` and gives you the
publish rate + std-dev.

## 4. Voice input

Tap the **microphone** icon in the composer (between the `+` and the
send button). Say:

> What was the last warning in `/rosout`?

Release. The transcript appears in the composer; tap send. Voice uses
the Android system `SpeechRecognizer` — Google's on-device model on
most phones, no audio leaves the device.

## 5. Image attachment

Take a screenshot of an RViz scene, a terminal showing an error, or a
photo of the robot itself. In Scry:

1. Tap the **+** icon in the composer
2. Choose **Gallery** (or **Take photo** to capture fresh)
3. Pick the image — it appears as a chip above the input
4. Type a question, e.g. `what's wrong in this RViz scene?`
5. Send

The agent uses your provider's vision model (Claude Sonnet, GPT-4o,
Gemini Pro, etc.) to actually look at the image. Useful for "the robot
is doing weird stuff and I don't even know how to describe it."

## What just happened under the hood

Every message you send goes through the same loop:

```
You type → ChatViewModel
  → AiProxyLoop builds: system prompt + tier-0 tools (~10 core MCP tools)
  → AI provider streams response
  → If AI calls a tool:
      - Read tool? → run immediately, send result back
      - Write tool? → show approval dialog → wait for your tap → run
  → AI continues until it sends final text
  → save to local Room DB
```

The AI doesn't have a persistent connection to your robot. Each tool
call is a fresh HTTP request to `scry-connect`, scoped to that turn.
Nothing crosses the cloud except the AI inference itself (and that's
zero-retention with most providers).

## When something breaks

Three places to look, in order:

1. **Look at the message in chat.** If the AI says "I tried `ros_topic_list`
   and got an error: …" — that's the connect's response. Usually means
   the robot's state changed (node crashed, topic stopped).
2. **Check the connect logs** on the robot: `journalctl --user -u
   scry-connect -f`. Per-call audit logs are in `/var/log/scry/audit.log`.
3. **File feedback** via Settings → Feedback in the app, or on the
   specific reply. Both go to the operator's dashboard.

## What's next

Now that you've kicked the tires:

- **[Use Scry](../use/index.md)** — the full feature tour (monitors,
  fleet view, multi-robot, etc.)
- **[Architecture](../architecture/index.md)** — how the pieces fit
  together if you want to extend or contribute
- **[MCP tools reference](../reference/mcp-tools.md)** — every tool
  the agent can call, with what it returns
