# Scry — Data Safety Form (Play Console)

This is the exact set of answers to paste into Play Console's **App
content → Data safety** form. Google asks them per data type;
inconsistent answers are the #1 reason Play rejects a listing.

Source of truth for these answers: [`docs/PRIVACY.md`](privacy.md).
Any change to one must be reflected in the other.

---

## High-level posture

| Question | Answer |
|---|---|
| Does your app **collect** any user data? | **Yes** — account info (email, name, user ID, optional role/company) to a Supabase database we operate, AND chat content sent on the user's behalf to their chosen AI provider. |
| Does your app **share** any user data with third parties? | **Yes** — when the user picks the OpenRouter cloud provider, chat content is sent to OpenRouter's API (which routes it on to the underlying model vendor). With the local Ollama provider, chat content stays on the user's network. Account info goes to Supabase as our data processor (not "sharing" in Play's sense — they process on our behalf under a DPA). |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — TLS to Supabase and AI providers. LAN traffic to scry-connect is plain HTTP (cleartext-allowed per `network_security_config.xml`) which we declare. |
| Do you provide a way for users to request that their data be deleted? | **Yes** — account deletion via email to info@phaneronrobotics.com (PRIVACY.md §3.3). On-device data via Android Settings → Apps → Scry → Clear data. |

**Framing for Play reviewers:**

- **Account data** (email, name, user ID, role, company) is collected by Scry, stored by Supabase (our processor). Required to use the app — Scry is a multi-device service that needs identity to sync.
- **Chat content + photos** flow direct from the phone to the user's chosen AI provider. We don't see them and don't store them server-side.
- **Robot data** flows direct from the phone to the user's robot on their LAN. Never leaves their network.

---

## Per-data-type entries

For each row below, in Play Console click the data type → tick the
checkboxes shown.

### Personal info

| Sub-type | Collected? | Shared? | Why | Required / Optional |
|---|---|---|---|---|
| **Name** | **Yes** | **No** | **Account management** — pre-filled from your Google/GitHub account when you sign in with OAuth; you can edit it on the profile screen. Stored in `public.profiles` so it can be restored on a different device. | **Optional** |
| **Email address** | **Yes** | **No** | **Account management** — your login identifier. Stored in `auth.users` (Supabase). Required to use Scry. | **Required** |
| **User IDs** | **Yes** | **No** | **Account management** — a Supabase-issued UUID identifies your account across devices. Stored in `auth.users.id`. | **Required** |
| Address | No | — | — | — |
| Phone number | No | — | — | — |
| Race / ethnicity | No | — | — | — |
| Political / religious | No | — | — | — |
| Sexual orientation | No | — | — | — |
| **Other info** | **Yes** | **No** | **Account management** — the role chip (Roboticist / ML / Student / Hobbyist / Other) and the optional company / lab text you typed on the profile screen. | **Optional** |

### Financial info

All **No**. We don't process payments, don't read banking info, don't
have a wallet.

### Health & fitness

All **No**.

### Messages

| Sub-type | Collected? | Shared? | Why | Required / Optional |
|---|---|---|---|---|
| Emails | No | — | — | — |
| SMS / MMS | No | — | — | — |
| **Other in-app messages** | **Yes** | **Yes** | **App functionality** — the chat content the user types is sent to the AI provider they chose. The AI's reply comes back to the device. We don't store chat content on a server we operate, **except** the optional feedback excerpt below. | **Required** (this is the app's core feature) |

When ticked, Play asks:
- **Purposes:** App functionality.
- **Processing purposes:** Optional → leave unticked.
- **Is this data collected ephemerally?** No (we store chat history on device so it survives restarts).
- **Is this data encrypted in transit?** Yes.
- **Can users request deletion?** Yes (via Android Settings → Clear data, and account/feedback deletion by email).

!!! note "Optional feedback excerpt"
    When a user taps the thumbs-up / thumbs-down on a reply, or uses
    Settings → Feedback, Scry sends their **preceding prompt** (capped at
    8 KB) and the **tool names** called that turn to a Supabase database
    we operate — never the tool arguments, tool results, or assistant
    text. This is user-initiated and disclosed in the
    [Privacy policy §3.4](privacy.md). It's covered by the same Messages
    data type; tick **collected** for our own backend in addition to
    **shared** with the AI provider.

### Photos and videos

| Sub-type | Collected? | Shared? | Why | Required / Optional |
|---|---|---|---|---|
| **Photos** | **Yes** | **Yes** | When the user attaches an image to a chat message (gallery pick or camera capture), the image is uploaded to the AI provider as part of that message. We don't keep a copy on any server. | **Optional** — the user is the one who decided to attach the image |
| Videos | No | — | — | — |

Same Play questions as Messages: app-functionality purpose, not
ephemeral (cached on device for chat history), encrypted in transit,
deletable via Clear data.

### Audio files

| Sub-type | Collected? | Shared? | Why | Required / Optional |
|---|---|---|---|---|
| **Voice or sound recordings** | **No** | — | Voice input launches Android's system speech-recognition dialog (`RecognizerIntent.ACTION_RECOGNIZE_SPEECH`). Only the recognised **text** flows into chat, never the audio. | — |
| Music files | No | — | — | — |
| Other audio | No | — | — | — |

Be explicit in the optional notes field: "Voice input uses Android's
system speech-recognition dialog; only the recognized text reaches
Scry. The audio is handled by the device's speech service (which may
process it in the cloud) and is never stored, transmitted, or read by
Scry."

### Files and docs

All **No**. We don't browse the filesystem, don't import arbitrary
documents.

### Calendar

All **No**.

### Contacts

All **No**.

### App activity

| Sub-type | Collected? | Shared? | Why | Required / Optional |
|---|---|---|---|---|
| App interactions | No | — | — | — |
| In-app search history | No | — | — | — |
| Installed apps | No | — | — | — |
| Other user-generated content | No | — | — | — |
| Other actions | No | — | — | — |

We do NOT analytics-track user clicks, screen views, button taps, etc.
Confirmed by the absence of any analytics SDK in the dependency list.

### Web browsing

All **No**.

### App info and performance

| Sub-type | Collected? | Shared? | Why | Required / Optional |
|---|---|---|---|---|
| Crash logs | No | — | — | — |
| Diagnostics | No | — | — | — |
| Other app performance data | No | — | — | — |

Confirmed: no Crashlytics, no Sentry, no Firebase Performance, no
Google Analytics in the dependency list. If we add one in the future
this section gets updated with the relevant boxes ticked.

### Device or other IDs

All **No**. We don't read the advertising id, don't read IMEI / serial,
don't write a custom install-id.

---

## Security practices

When Play asks:

- **Is all of the user data collected by your app encrypted in transit?**
  Yes (LAN traffic to scry-connect is cleartext-allowed by design; we
  flag this in the network security config and in the privacy policy).
- **Do you provide a way for users to request that their data be deleted?**
  Yes — via the system Android Settings → Apps → Scry → Clear data.
  Document this in the app's Settings screen helper text too.

---

## "Independent security review"

Optional. Skip for v0.1.0 — fill in later if we run one.
