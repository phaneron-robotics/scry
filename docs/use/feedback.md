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

Tool arguments and results are excluded because they can leak robot
internals (IPs, topic message values, sensor data). Your prompt plus the
names of the actions involved is enough for Phaneron Robotics to triage
"which kind of question went wrong."

## Settings → Feedback (general)

For feedback that isn't tied to one specific reply:

1. Open the chat session drawer (left side) → **Settings** at the
   bottom
2. Tap **Feedback**
3. Pick **General**, **Bug**, or **Feature**
4. Pick a sentiment (Good / Neutral / Bad)
5. Optional: free-form comment
6. Tap **Send feedback**

You need at least one of (sentiment, comment). Tapping **Send** with
nothing filled in shows an inline error asking you to pick a sentiment
or write something. (A separate "Rate us on Google Play" invite appears
on the thank-you screen after you submit — that's the Play rating, not
part of the form.)

## Where this lands

| Where | What |
|---|---|
| Phaneron Robotics' secure database | One row per submission, visible only to you and to Phaneron. |
| Phaneron Robotics review | The team triages feedback regularly and updates its status as it's reviewed and addressed. |

## Sign-in and opting out

Sending feedback **requires sign-in**, but that's enforced only when you
submit: the thumbs and the Feedback form are always visible. If you're
signed out, tapping a thumb or hitting **Send** surfaces an error
("Couldn't send feedback…") instead of submitting — the controls don't
disappear.

The feature is on by default and there's currently no in-app toggle to
disable it. If you want to opt out entirely, don't tap the thumbs and
don't submit the form. Nothing is ever sent without an explicit tap.
