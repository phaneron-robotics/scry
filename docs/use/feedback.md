# Sending feedback

Two channels, both write to the same `feedback` table in the Phaneron
Supabase project.

## Inline thumbs on a specific reply

Every settled assistant message has thumbs-up and thumbs-down icons in
the action row below it. Tap one:

- **thumbs up** records `sentiment=positive` for that reply
- **thumbs down** records `sentiment=negative`
- A snackbar appears for ~3 seconds with an **Add a note** action
- Tap **Add a note** to open a small dialog and type a free-form
  comment (up to 4000 chars)
- After one tap, both thumbs grey out — one vote per message per
  session

### What gets sent

| Field | Sent? | Notes |
|---|---|---|
| Your sentiment (thumbs up / thumbs down) | Yes | The actual rating |
| Your preceding question | Yes | Trimmed to 8 KB |
| Tool names called this turn | Yes | Just names — e.g. `["ros_topic_hz","fleet_overview"]` |
| The assistant's reply text | No | Never sent |
| Tool **arguments** | No | Never sent |
| Tool **results** | No | Never sent |
| Robot name | No | Not part of the feedback row |
| App version, OS version, locale | Yes | For triage only |

Tool args/results are excluded because they can leak robot internals
(IPs, topic message values, sensor data). The user's prompt + tool
names is enough for the operator to triage "which kind of question
went wrong."

## Settings → Feedback (general)

For feedback that isn't tied to one specific reply:

1. Open the chat session drawer (left side) → **Settings** at the
   bottom
2. Tap **Feedback**
3. Pick **General**, **Bug**, or **Feature**
4. Pick a sentiment (Good / Neutral / Bad)
5. Optional: 1–5 stars
6. Optional: free-form comment
7. Tap **Send feedback**

You need at least one of (sentiment, stars, comment) — pure empty
submissions are rejected client-side. The submit button is disabled
otherwise.

## Where this lands

| Where | What |
|---|---|
| `public.feedback` table on Phaneron's Supabase project | One row per submission. RLS scoped — you can only see your own rows. |
| Operator dashboard | Phaneron triages weekly. Status field flips to `reviewed` / `fixed`. |

## Disabling

Inline thumbs and the feedback form both **require sign-in**. If you
don't have a Phaneron account, the inline icons hide and the Feedback
settings page tells you to sign in first.

The feature is on by default and there's currently no in-app toggle
to disable it. If you want to opt out entirely, don't tap the thumbs
and don't submit the form. Nothing is ever sent without an explicit
tap.
