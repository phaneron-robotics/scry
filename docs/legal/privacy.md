# Scry — Privacy Policy

**Effective date:** 17 May 2026
**Last updated:** 23 May 2026

This privacy policy explains what data Scry handles, where that data
goes, and the controls you have over it. Scry is published by
**Phaneron Robotics, Inc.** ("we", "us"). The app is distributed
through the Google Play Store under the package id
`com.phaneronrobotics.scry`.

If you have questions or want your data deleted, email
**info@phaneronrobotics.com**.

---

## 1. What Scry is

Scry is a mobile client for debugging ROS 2 robots. It connects to a
`scry-connect` server running on your robot or development host and
provides a chat-style interface where Scry can read the robot's state
and (with your explicit approval) take actions on it.

We do not operate any cloud backend. Scry runs entirely on your
phone, communicates directly with **your** robot's scry-connect
server, and (if you opt into a cloud AI provider) forwards your chat
messages directly from the phone to **that provider's** API.

---

## 2. Data Scry stores on your device

All of the following live in app-private storage. Other apps cannot
read them and they are excluded from the system backup.

| Category | What | Where |
|---|---|---|
| **Robot connection profiles** | host, port, optional pairing token, network name | App-private SQLite database (not encrypted; protected by Android's app sandbox) |
| **Chat history** | your messages, Scry's responses, and the results it read from the robot | App-private SQLite database (not encrypted; protected by Android's app sandbox) |
| **API keys** | the OpenRouter API key you paste in | Encrypted on-device storage (AES-256-GCM, master key in the Android Keystore) |
| **App preferences** | provider/model choice, Ollama URL, UI toggles | Encrypted on-device storage |
| **Cached attachments** | screenshots and gallery imports you attach to chat messages | App cache; cleared by the system under low-storage pressure |

You can wipe everything by **Settings → Clear all data** in Android's
app settings (this is the standard Android control; we don't add a
custom wipe button because the system one is more reliable).

---

## 3. Data Scry sends off your device

Scry forwards data to **two kinds** of external services. Both are
under your direct control.

### 3.1 Your robot's scry-connect server

When you pair Scry to a robot, every read/write tool call and every
SSE topic subscription goes to that robot's IP over plain HTTP on
your LAN (or HTTPS if you've configured a TLS terminator in front of
scry-connect). The traffic stays inside your own network unless you
expose scry-connect's port to the internet — which we do not
recommend.

**What we send:** the tool name, its arguments, and the chat context
needed to render the response. **What we receive:** the tool result.

We don't telemeter any of this back to us. We have no servers.

### 3.2 The AI provider you chose

Scry supports two AI providers. The chat-message bytes (your text,
the assistant's reply, any image attachments you sent, and the tool
results returned by the robot) are sent to **whichever provider you
pick in Settings → AI providers**:

| Provider | Endpoint | Privacy policy |
|---|---|---|
| OpenRouter (cloud) | `openrouter.ai` — which then routes your request to the underlying model vendor (Anthropic, Google, Meta, etc.) you selected | https://openrouter.ai/privacy — and the routed vendor's own policy |
| Ollama (local) | the URL you entered in Settings (defaults to your robot's host on port 11434) | not applicable — Ollama runs on your machine and does not send data over the internet |

When using OpenRouter, your chat content is subject to OpenRouter's
privacy policy **and** the data-handling terms of whichever model vendor
your chosen model routes to — including any retention they apply for
abuse / safety review and any model-training policies. We pass your
OpenRouter API key in the `Authorization` header on each request; we
never see the request or response content because there is no Scry
backend.

**Ollama is the only AI provider option that keeps all chat data on
your local network.** It is the default suggested in onboarding for
exactly this reason.

### 3.3 Account (required to use Scry)

Scry requires an account. There are four ways to create one:

| Method | What we receive |
|---|---|
| **Continue with Google** | Email + name from your Google account, plus a Google-issued user ID. We never see your Google password. |
| **Continue with GitHub** | Email + name from your GitHub account, plus a GitHub-issued user ID. We never see your GitHub password. |
| **Email magic link** | Email only. You finish sign-in by tapping a link we email you. |
| **Email + password** | Email + a password you choose. The password is sent over TLS, hashed (bcrypt) by Supabase, and never stored in plain text — we as the operator cannot read it. |

After auth completes, the **profile screen** asks for two more things:

| Field | Required |
|---|---|
| Your name (pre-filled from Google/GitHub if available) | Optional — you can edit or clear it |
| Company / lab | Optional |
| Role (Roboticist / ML engineer / Student / Hobbyist / Other) | Optional |

**Why we require an account:**

- To sync chat history and robot pairings across your devices.
- To restore your work if you reinstall.
- So we can tell you about meaningful product updates (rarely — not a
  newsletter).

**Where it lives:** a Supabase project we run in the US-West
(`us-west-2`, Oregon) region. The tables involved:

- `auth.users` — managed by Supabase. Holds your email, hashed password
  (only if you signed up with email/password), and the OAuth provider
  identity if you signed in with Google/GitHub.
- `public.profiles` — joined 1:1 to `auth.users` by user ID. Holds
  the role/company you typed on the profile screen plus app version,
  Android SDK level, and locale.
- `public.feedback` — populated only when you send optional feedback
  (see §3.4). Holds the feedback you submitted, linked to your user ID.

Encryption: TLS 1.3 in transit, AES-256 at rest, password hashes via
bcrypt (Supabase Auth default). **Row-level security** ensures the app
key shipped in the apk can only read or modify **your** profile row —
not any other user's.

**Supabase is the data processor**; Phaneron Robotics is the data
controller. The Supabase DPA covers their handling obligations under
GDPR Art. 28.

**What we never send to our backend:** your full chat content, robot
data (topics, nodes, services, parameters), your OpenRouter API key,
screenshots, and voice transcripts. None of that touches our database.
See §3.1 and §3.2 for where it goes instead. The one exception is the
optional feedback you choose to send — see §3.4.

### 3.4 Optional feedback (only when you send it)

Scry has an optional feedback path you trigger yourself: the thumbs-up /
thumbs-down icons under an assistant reply, and the **Settings →
Feedback** form. Nothing here is sent unless you tap one of those.

When you do, we send the following to the same Supabase project (the
`public.feedback` table):

- For a thumbs rating: your **preceding question** (the prompt text,
  capped at 8 KB) and the **names of the tools** Scry called that turn —
  e.g. `ros_list_topics`. We do **not** send the tool arguments, the
  tool results, the assistant's reply text, or any attachment content.
- For the Feedback form: the category, sentiment, and any comment you
  typed.

This excerpt helps us tell whether a given kind of question worked. It's
the only chat-derived text that ever reaches our backend, and only ever
because you asked us to look at that reply.

**After the first connect (planned):** in a future version, on your
first successful robot pair we may record a `first_connect_meta` blob
on your profile row — the robot's ROS distribution, RMW implementation,
and node/topic counts, never the hostname, IP, or any topic contents.
This is **not** collected today.

**Deletion:** email **info@phaneronrobotics.com** asking us to
delete your account. We honour deletion requests within 30 days;
usually within 24 hours. The deletion is a SQL `DELETE` on the
`auth.users` row, which cascades to your `profiles` row **and to any
feedback rows you submitted** (including the chat excerpts they
contain). Your session JWT becomes invalid on next API call; the app
pushes you back to the sign-in screen.

**Lawful basis:** Contract (GDPR Art. 6(1)(b)) — the account is
necessary to provide the service. You can terminate the contract at
any time by requesting deletion.

**Signing out:** Settings → Sign out clears your session locally
without deleting your account. Your row stays in our database so you
can sign back in later on this or any other device.

---

## 4. Permissions

Scry requests the following Android permissions. The feature
permissions (camera, microphone) are requested the first time you use
the feature; notifications are requested at app launch on Android 13+.
None are requested at install time.

| Permission | What it's for |
|---|---|
| `INTERNET` + `ACCESS_NETWORK_STATE` + `ACCESS_WIFI_STATE` | Talking to scry-connect on your LAN and to AI providers (when you select a cloud provider). |
| `CAMERA` | Optional: take a photo to attach to a chat message ("look at this LED — what's it indicating?"), and scan the pairing QR shown by scry-connect. |
| `RECORD_AUDIO` | Optional: voice-to-text input in chat. Routed to your phone's system speech-recognition dialog (Android `RecognizerIntent`) — we only receive the recognized text and never read or store the audio. |
| `POST_NOTIFICATIONS` | Optional (Android 13+): surface background-monitor alerts as system notifications. Requested at app launch; in-app chat alerts still work if you deny it. |

Picking an image from your gallery uses Android's **Photo Picker**, and
attaching a file uses the system document picker — both grant Scry a
one-shot read of only the item you select, so **no storage / media
permission** is requested.

We do not request location, contacts, always-on microphone, foreground
service permissions, advertising ID, or any other ambient-collection
permission. The full list, with the reason for each, is on the
[Permissions](../reference/permissions.md) page and visible in the app
under **Settings → Permissions**.

---

## 5. Analytics, crash reporting, advertising

**None of the above.** Scry ships with no analytics SDK, no crash
reporter, no advertising ID integration, and no third-party tracker —
no Firebase, Crashlytics, Sentry, Google Analytics, AppsFlyer, Adjust,
Mixpanel, or anything similar.

If a future version adds crash reporting we will (a) make it opt-in,
(b) document it in this policy, and (c) bump the "Last updated" date
at the top.

---

## 6. Children

Scry is built for adult developers working on robotics projects. It
is not directed at children under 13 (or under 16 in jurisdictions
covered by GDPR-K), and we do not knowingly collect data from
children.

---

## 7. Data subject rights (GDPR / CCPA / DPDPA / similar)

You have three layers of control depending on which data you mean:

1. **On-device data** (chat history, robot profiles, API keys,
   attachments): wipe via Android **Settings → Apps → Scry → Clear
   data**. We can't see this data and don't need to act on a request.
2. **Profile capture data** (§3.3 — the row in our Supabase database):
   email **info@phaneronrobotics.com** to exercise access,
   correction, deletion, portability, or to withdraw consent. We honour
   requests within 30 days. Identity verification is via reply from the
   email address on the row.
3. **Chat data sent to your chosen AI provider** (§3.2): we never see
   this and can't act on it. Exercise rights against OpenRouter — and
   the model vendor your chosen model routes to — per their privacy
   policies. (Optional feedback you send us, §3.4, is the one piece of
   chat-derived text we hold, and it's covered by layer 2 above.)

We do not sell, share for cross-context behavioural advertising, or
otherwise monetise the data described in §3.3. There is no such
disclosure to opt out of.

---

## 8. Security

- API keys are encrypted at rest with Android EncryptedSharedPreferences
  (AES-256-GCM, master key in the Android Keystore).
- Chat history and robot profiles live in the app-private SQLite
  database (`databases/scry.db`); cached and downloaded files
  (attachments, map tiles) live in `getCacheDir()`. Both are inside the
  Android app-private sandbox and not readable by other apps. These
  stores are not separately encrypted beyond the sandbox. (Downloaded
  ROS bags use `getExternalFilesDir()` under `Android/data/` so they can
  be shared off the device.)
- Requests to the cloud AI provider (OpenRouter) use HTTPS. LAN traffic
  to scry-connect is allowed over plain HTTP, because most ROS 2
  deployments don't have a TLS terminator on the robot — if you expose
  scry-connect outside the LAN, put a TLS proxy in front.

---

## 9. Changes to this policy

When we change this policy, we update the date at the top and post a
changelog entry in the GitHub repository under `docs/PRIVACY.md`. We
will not retroactively widen data-collection scope on data we
collected before the change.

---

## 10. Contact

**info@phaneronrobotics.com**

GitHub: https://github.com/phaneron-robotics
