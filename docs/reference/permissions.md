# Android permissions

Every runtime permission Scry asks for, what it's for, and what happens
if you deny.

## At install time (Play Store)

These are listed in the Play Store before you install:

| Permission | Why |
|---|---|
| **Internet** | Talking to your AI provider and `scry-connect`. App is useless without it. |
| **Access network state** | Detect when WiFi changes so the connection chip can update. |
| **Access WiFi state** | Same — and for the LAN discovery / QR pairing flow. |
| **Camera** | Listed at install but only requested when you tap the QR scanner or "Take photo". |
| **Microphone** | Same — requested when you first tap the mic button. |

## At runtime (requested in-app the first time)

| Permission | When requested | If denied |
|---|---|---|
| **Camera** | First tap on QR scanner or "Take photo" in chat | QR scanner falls back to manual entry; photo button stays inert |
| **Microphone** | First tap on the chat mic button | Mic button greys out; toast on subsequent taps |
| **Notifications** | App launch on Android 13+ | Background monitor alerts won't surface as system notifications (in-app chat alerts still work) |

## What Scry never asks for

- **Location** — not now, not planned
- **Contacts**
- **SMS / call log**
- **Advertising ID**
- **Health data**
- **Always-on microphone** (mic is push-to-talk only)
- **Storage write outside the app sandbox**

If a future build needs any of the above, it'll be opt-in with a
specific feature gating it (e.g. "share location with the robot for
geofencing" → location permission, only when that feature is enabled).

## Files don't need a permission

When you tap the **+ → File** picker, Android grants Scry a one-shot
read URI for the specific file you picked. There's no "storage
permission" to grant — the picker model means you authorize per-file.

## Managing permissions

In the app: Settings → **Permissions**. Each row links to the system
permission page for that capability.

System-wide: Android Settings → Apps → Scry → Permissions.

Granting or revoking is non-destructive — the app handles either
gracefully.
