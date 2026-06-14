# Background monitors

Set a condition like "alert me if the battery drops below 20%" — Scry
watches a numeric field on a topic in the background and fires an alert
into chat the moment the condition trips.

## How to set one

Just ask Scry:

```
Watch /battery_state and alert me if percentage drops below 20.
```

Scry sets up the monitor and confirms it in chat ("Monitor armed:
/battery_state.percentage < 20"). The monitor is now live.

A monitor watches a **numeric field on a topic** against a threshold,
using a comparison like below / above / equals. Examples:

- "alert me if `/battery_state.percentage` drops below 20"
- "tell me when `/cpu_temp.temperature` goes above 80"
- "watch `/odom.pose.pose.position.x` and ping me when it passes 5"

!!! note "What monitors watch today"
    Monitors compare a numeric field against a threshold. Conditions
    like publish-rate, service availability, or "node X died" aren't
    background monitors yet — for those, ask Scry to check them directly
    in chat (e.g. "is `/odom` still publishing?", "is the costmap-clear
    service available?").

## Edge-triggered, not level-triggered

Monitors fire **once per false-to-true transition**, not continuously.
If your battery drops to 19% the monitor fires; it does **not** keep
firing every second while battery stays at 19%. Re-fires when battery
goes above the threshold and then back below.

This matches what you actually want: notifications when something
changed, not a stream of "still bad."

## Where alerts show up

When a monitor trips, an **assistant message** appears in chat:

> Note: Monitor fired: `/battery_state.percentage < 20` — current value 18.4
>
> [robot context excerpt]

It looks identical to a regular assistant reply (same alignment, same
brand mark). Difference is the Note: glyph and the explicit "Monitor
fired" prefix.

Scry sees this message on the next turn, so you can ask follow-ups like
"what's draining the battery?" and it'll have full context.

## Where monitors run

Monitors run on your **phone**, watching the robot's live data:

- The phone keeps a live stream open to the robot for each monitor and
  checks the condition as new data arrives.
- They run while the app is open and continue while it's in the
  background, but they don't persist across a full app restart.

That makes monitors ideal for "I'm working with the robot right now and
don't want to miss this." They're **not** a replacement for a permanent
alerting system on the robot itself.

## Listing and stopping monitors

Ask Scry to list your active monitors:

```
list my active monitors
```

You'll get each monitor's condition and current value, rendered as a
chip strip above the composer with a **Stop** button on each chip. You
can also just tell Scry:

```
stop the battery monitor
```

and it'll cancel it for you.

## Notifications when the app is backgrounded

Monitors keep running even when Scry is in the background or your
screen is off. When one trips, you get:

1. A standard Android **notification** (requires the Notifications
   permission)
2. The chat message appears in app on next foreground

The notification is just "Monitor fired on [robot name]" — tap it to
open Scry directly to the chat where the alert landed.
