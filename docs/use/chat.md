# Chat with the agent

The Scry tab is your primary surface. Streaming responses, live tool
results, multi-turn context.

## Sending a message

Type in the composer at the bottom, tap **Send**. The agent will:

1. Stream a short "thinking" indicator while picking tools
2. Stream text + inline tool result cards as they arrive
3. Settle into the final reply with action icons below it

You can also tap a **suggestion chip** on the empty state — those
cycle on each new session. The shuffle button rotates them.

## What's an "inline tool result card"

When the agent calls a tool that returns structured data, Scry doesn't
print the raw JSON — it renders a typed card. For example:

- `ros_topic_hz` returns rate + std-dev → renders a big-number card
- `fleet_overview` returns the robot list → renders a fleet table
- `ros_node_info` returns the publishers/subscribers → renders a tabbed panel
- `tf_tree` returns the transform tree → renders a hierarchical view

The agent's prose adds context and anomaly callouts *above* the card;
it never repeats what the card already shows.

## Multi-turn

Conversations are persisted in Room (local SQLite). The agent sees the
full conversation history on every turn, so follow-ups work:

```
You: what topics are on /odom*?
AI: [lists /odom, /odom_filtered]
You: what's the rate on the second one?
AI: [calls ros_topic_hz on /odom_filtered]
```

Conversations are **per-robot**. Switching robots in Fleets switches the
chat surface too.

## Action icons under each assistant reply

Every settled assistant message has a row of small icons:

| Icon | What |
|---|---|
| (scry mark) | Subtle indicator that the agent finished this turn |
| Copy | Copy the assistant's text to clipboard |
| Retry | Re-run this turn — sends the prior user message again |
| / | Flag this reply (see [Sending feedback](feedback.md)) |
| ⋮ More | Edit message, fork conversation, delete from here |

## Editing and forking

- **Long-press** a user message → **Edit**. You can rewrite your prompt
  and the agent re-runs from there, discarding everything after.
- **Long-press** any message → **Fork**. Splits the conversation into
  a new session at that point, preserving the original.

Useful when you're exploring "what if I asked it differently."

## Robot switching

The chat top-bar shows the active robot's name and live latency:

```
Scry ▾
deep-dell · 33ms
```

Tap the dropdown to switch robots. The chat surface swaps to that
robot's history. Your in-flight composer text follows you.

## Model picker

Tap the **Scry** chip at the top to change AI provider/model. The
picker shows OpenRouter's 300+ models grouped by tier (Free, Cheap,
Mid, Premium) plus any Ollama models discovered on the robot.

The selection is per-device, not per-conversation — switching models
mid-conversation works fine.
