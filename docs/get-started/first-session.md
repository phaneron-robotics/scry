# First session

Your phone is paired with the robot. Time to actually use Scry. Five
things to try, in order — each one shows off a different capability.

## 1. "What's my robot's health?"

In the chat composer at the bottom of the Scry tab, type:

```
What's my robot's health?
```

Tap **Send**. Scry checks the robot and renders a health snapshot —
nodes alive, topics publishing, recent ROS error/fatal counts, and a
diagnostics rollup — with a short plain-English summary above it. (Ask a
follow-up and Scry can pull related details on demand, like the battery
level or the ROS domain ID.)

The data is **live**: every answer reflects the robot right now, with no
caching. A typical reply takes a second or two.

## 2. "What topics are publishing?"

```
What topics are publishing right now?
```

Scry lists the active topics grouped by namespace, each with its type
and publisher/subscriber counts. Ask about a specific topic (or its
rate, e.g. "what's the rate on `/odom`?") to drill in — Scry measures
the publish rate on demand rather than listing it for every topic.

## 3. Inspect a single topic

```
What's on /odom?
```

If `/odom` exists, Scry reads a sample message and shows it. For
high-frequency topics (IMU, camera, lidar) it reports the publish rate
and stability instead of flooding you with messages.

## 4. Voice input

Tap the **microphone** icon in the composer (between the **+** and the
send button). Your phone's speech-recognition dialog opens — say:

> What was the last warning in `/rosout`?

When you stop speaking, Scry sends the recognised text as your message
automatically. Recognition is handled by your phone's speech service;
Scry only ever receives the text. See [Voice input](../use/voice.md).

## 5. Image attachment

Take a screenshot of an RViz scene, a terminal showing an error, or a
photo of the robot. In Scry:

1. Tap the **+** icon in the composer.
2. Choose **Gallery** (or **Take photo** to capture a fresh one).
3. Pick the image — it appears as a chip above the input.
4. Type a question, e.g. `what's wrong in this RViz scene?`
5. Send.

Scry uses your provider's vision model to actually look at the image —
great for "the robot is doing something weird and I can't even describe
it." This needs a model that supports images; see
[Choose your AI](choose-ai.md).

## More things to ask

Once you're comfortable, these are the kinds of questions Scry handles
well:

- *Why is `/cmd_vel` not publishing?*
- *Plot the IMU acceleration for five seconds.*
- *Which nodes are using the most CPU right now?*
- *Set `max_vel_x` on the controller to 0.4 and confirm it took.*
- *Alert me if the battery drops below 20%.*
- *Which robot in my fleet is missing `/scan`?*

## How it flows

Every message follows the same simple loop: you ask, Scry decides what
to check, it reads the robot live, and it explains the result. If a step
would *change* the robot — publishing, setting a parameter, calling a
service — Scry pauses and asks you to approve it first. Reading is free;
acting asks first.

Nothing is cached and nothing routes through a Scry cloud — your phone
talks to your AI provider and to your robot directly.

## When something breaks

Two places to look, in order:

1. **Read the reply in chat.** If Scry says it tried something and got an
   error, that's the robot's own response — usually a node that crashed
   or a topic that stopped.
2. **Check the connect on the robot.** If you installed it as a service,
   view its log with `journalctl --user -u scry-connect -f`.

You can also flag a reply with the thumbs-down icon, or send a note from
**Settings → Feedback** — see [Sending feedback](../use/feedback.md).

## What's next

- **[Use Scry](../use/index.md)** — the full feature tour: monitors,
  fleet view, multi-robot, and connecting remotely.
- **[How Scry works](../how-it-works.md)** — what the phone and the robot
  each do, and why your robot data never routes through a Scry cloud.
- **[What Scry can do](../reference/mcp-tools.md)** — everything Scry can
  inspect and act on, on a robot.
