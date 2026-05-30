# Beta testing Scry

Scry is currently in **closed Internal Testing** on Google Play.
This page tells testers how to join, how to install, and what to
report back.

> **Operator note:** the operator needs to add each tester's
> Google account to the Internal Testing list in Play Console
> before the opt-in link works. See "For the operator" at the
> bottom of this page.

## How to join (testers)

1. **Send your operator the Google account email** you want to
   test with. It has to match the account signed in on the phone
   that'll install the app. Personal Gmail is fine; a Google
   Workspace account works too.
2. **Wait for confirmation** that you've been added (usually
   same day). Until you're added, the opt-in link below will
   show a "no testing app here" page.
3. **Tap the opt-in URL** the operator sent you on the phone
   where you want to install Scry. The link looks like:

   ```
   https://play.google.com/apps/internaltest/<long-id>
   ```

   It opens Play Store, shows a "Become a tester" page, and asks
   you to accept. Tap **Accept**.
4. **Install from the Play Store listing** you land on after
   accepting. Scry shows up in your Play library just like any
   other app — updates ship automatically.

The Play Store will show `com.phaneronrobotics.scry (unreviewed)`
as the app name while the listing is still pre-review. Once
Google reviews the app the display name flips to **Scry**.

## What to test

This beta carries real new features — both bug reports and
"this felt good" feedback are useful.

| Surface | What to try |
|---|---|
| **Account** | Sign in with Google, GitHub, magic-link email, or password. Sign out from Settings → Account. Sign back in — your profile (role / company) should still be there. |
| **Onboarding tour** | First launch goes through five swipeable pages. Skip works; reaching the end finishes the tour. Replay from Settings → Account → Show app tour again. |
| **Chat** | Connect to a robot (QR or LAN scan), ask questions, expect inline rendered tool results. Voice-to-text mic button. File / image attach (+) in the composer. |
| **Inline thumbs** | / below each assistant reply. Snackbar should pop with an "Add a note" link. The buttons grey out after one tap per message. |
| **Feedback form** | Settings → Feedback. Pick kind, rate stars, write something, submit. Confirm the thank-you screen appears. |
| **Robot pairing / fleets** | Add a robot via QR or manual host. Switch between robots from the chat top-bar chip. |
| **Permissions** | Camera (QR + photos), microphone (voice), notifications (background monitors). Settings → Permissions opens the system pages. |

## How to report a bug or feedback

Three channels, in order of preference:

1. **In-app, Settings → Feedback.** This goes straight to the
   operator's database with your device info attached. Use this
   for anything you can describe in a sentence or two.
2. **In-app inline thumbs.** Tap on the specific assistant
   reply that was bad, then tap **Add a note** in the snackbar.
   Most useful for "this answer was wrong / hallucinated /
   missed an obvious thing" — the operator gets the conversation
   excerpt attached automatically.
3. **Email `info@phaneronrobotics.com`.** Last resort, or for
   anything that doesn't fit (login broken, app crashes on
   launch, can't sign in to leave in-app feedback).

For crashes that take down the app: open Play Store → Scry → "About
this app" → bottom of page has the Play Console crash details.
If you can copy a stack trace, paste it in an email.

## Known issues in this beta

- The temporary app name shows as `com.phaneronrobotics.scry
  (unreviewed)` in Play Store. Will fix itself after Google's
  first listing review.
- Anonymous / device-id-only mode is gone. You must sign in.
- Robots are not synced across devices yet — pair on each phone
  separately. Chat history is also local-only for now.

## For the operator

Bring testers onto the Internal Testing track:

1. **Play Console → Scry → Testing → Internal testing → Testers tab.**
2. Pick one of:
   - **Create email list** (recommended for >5 testers): name
     it, paste comma-separated emails, save. Reusable across
     future tracks.
   - **Direct entry** for one-off testers.
3. Hit **Save changes**.
4. Copy the **opt-in URL** from the same page (under the tester
   list — Google's shortlink). Send it to the testers along with
   a pointer to this doc.

If a tester says "the opt-in link shows no app", they're not on
the list — add the exact email they're using on their phone.

### Adding a new build

```bash
# On master, bump versionName in app/build.gradle.kts and add a
# CHANGELOG.md section, then:
git tag v0.2.0-beta.2
git push origin v0.2.0-beta.2
```

The `.github/workflows/release.yml` workflow builds the AAB,
uploads it to the Internal track, and writes the CHANGELOG.md
section into Play's "What's new" field automatically.

Testers get the update through Play Store's normal auto-update
flow — usually within an hour, force-refresh by pulling-to-refresh
on their Play library.

### Supabase prerequisites

Before testers can use the feedback feature in 0.2.0-beta.1:

```sql
-- Run via Supabase SQL Editor on the prod project. Idempotent —
-- safe to re-run. Contains both the profiles table (used by
-- auth) and the feedback table.
\i backend/supabase_schema.sql
```

Or paste the file contents into the SQL Editor manually.

Verify after running:

```sql
select count(*) from public.profiles;   -- should not error
select count(*) from public.feedback;   -- should not error
```

### Operator triage cadence

- Inline thumbs (specifically) — daily glance at
  `select * from public.feedback where kind='inline_thumb' and
  sentiment='negative' order by created_at desc limit 20;`
- Top-level feedback form — same query without the sentiment
  filter, weekly.
- Status field on each row flips to `'reviewed'` / `'fixed'` as
  the operator triages from the dashboard (service-role key
  required for UPDATE — clients can only INSERT).
