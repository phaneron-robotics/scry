# Chat with Scry

The Scry tab is your main surface. Responses stream in live, tool
results render as you go, and the whole conversation stays in context
across turns.

## Sending a message

Type in the composer at the bottom and tap **Send**. Scry will:

1. Show a short "thinking" indicator while it decides what to check
2. Stream its reply, with result cards appearing inline as data arrives
3. Settle into the final answer, with action icons beneath it

On the empty state you can also tap the **suggestion chip** to get
started — it shows one suggestion that rotates each session, and the
shuffle button cycles to another.

## Inline result cards

When Scry looks something up on the robot, it doesn't dump raw data — it
renders a typed card. For example:

- A topic's rate → a clear rate-and-stability card
- The fleet list → a per-robot table
- A node's connections → a tabbed publishers/subscribers panel
- The transform tree → a hierarchical view

Scry's text adds context and flags anything unusual *above* the card; it
never just repeats what the card already shows.

## Multi-turn conversations

Conversations are saved on your device, and Scry sees the full history
each turn, so follow-ups work naturally:

```
You:  what topics are on /odom*?
Scry: lists /odom and /odom_filtered
You:  what's the rate on the second one?
Scry: checks /odom_filtered and reports its rate
```

Conversations are **per-robot** — switching robots switches the chat to
that robot's history.

## Action icons under each reply

Every finished reply has a row of small icons:

| Icon | What it does |
|---|---|
| Scry mark | Marks that Scry finished this turn |
| Copy | Copies the reply to your clipboard |
| Retry | Re-runs the turn from your last message |
| Thumbs up | Mark the reply helpful — sends feedback (see [Sending feedback](feedback.md)) |
| Thumbs down | Mark the reply not helpful — sends feedback (see [Sending feedback](feedback.md)) |
| More (⋮) | Edit message, fork the conversation, or delete from here |

## Editing and forking

Tap the **More (⋮)** icon under a message to open its actions:

- **Edit** (your own messages only) — rewrite your question. Scry
  re-answers from that point, discarding what came after.
- **Fork** — branch the conversation into a new session from that
  point, keeping the original intact.
- **Delete from here** — drop this message and everything after it.

Handy when you want to explore "what if I'd asked it differently."
(Long-pressing a message just selects its text for copying.)

## Switching robots

The top bar shows the active robot's name and its live connection
latency. Tap it to switch robots — the chat swaps to that robot's
history, and anything you've already typed comes along with you.

## Choosing a model

Tap the **Scry** chip at the top to change the model behind the
assistant. The picker has a **Cloud** tab — OpenRouter models grouped
into Recommended, Free, and Paid, with each row badged by price tier
(FREE / $ / $$ / $$$) — and a **Local** tab listing any Ollama models it
finds on your network. Your choice is per-device and you can switch it
mid-conversation without losing anything. See
[Choose your AI](../get-started/choose-ai.md) for how to set this up.
