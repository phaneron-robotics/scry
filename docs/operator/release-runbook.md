# Scry Android — Release Runbook

End-to-end procedure for cutting a release. Steady state is:

```bash
git tag v0.1.2 && git push --tags
```

…which fires `.github/workflows/release.yml`, which builds a signed
AAB, pushes it to the Play Store Internal Testing track, and publishes
a GitHub Release with the AAB attached. You then promote the
Internal-track release to Production from the Play Console (manual
button).

This document covers:
- The **one-time setup** (already done for v0.1.0, listed here so
  future contributors can reproduce it on a new machine).
- The **per-release** steps.
- **Troubleshooting** for the common failures.

---

## One-time setup

### 1. Upload keystore

The keystore lives **only** on the release engineer's laptop + secure
backups. Never commit it.

```bash
keytool -genkeypair -v \
  -keystore ~/scry-upload.jks \
  -alias scry-upload \
  -keyalg RSA -keysize 4096 \
  -validity 36500 \
  -storetype PKCS12
```

Distinguished-name fields used for the initial keystore:
- CN: `Deep Kotadiya`
- OU: `Scry`
- O: `Phaneron Robotics Inc.`
- L: `Boston`, ST: `MA`, C: `US`

**Backup `~/scry-upload.jks` to two independent locations** (USB
drive + password manager / private cloud). If the keystore is lost
the only path back is Google's [lost-key recovery flow](
https://support.google.com/googleplay/android-developer/answer/7384423),
which takes weeks and requires re-signing every future release with
a new key registered through Play App Signing.

### 2. `keystore.properties` (local builds)

Create at the repo root (already gitignored):

```properties
storeFile=/home/<user>/scry-upload.jks
storePassword=<password>
keyAlias=scry-upload
keyPassword=<same as storePassword, unless you set a separate one>
```

Confirm gradle reads it:

```bash
./gradlew :app:signingReport --quiet | grep -A 2 "Variant: release"
```

You should see `Config: release`, `Store: <path to .jks>`,
`Alias: scry-upload`.

### 3. GitHub Actions secrets (CI builds)

Settings → Secrets and variables → Actions → New repository secret.
Add five secrets:

| Name | Contents |
|---|---|
| `SCRY_KEYSTORE_BASE64` | `base64 -w 0 ~/scry-upload.jks` output (one giant blob, no newlines) |
| `SCRY_KEYSTORE_PASSWORD` | the keystore password |
| `SCRY_KEY_ALIAS` | `scry-upload` |
| `SCRY_KEY_PASSWORD` | the key password (often equal to keystore password) |
| `PLAY_SERVICE_ACCOUNT_JSON` | the full JSON of a Google Cloud service account with Play Developer API write access (see next step) |

### 4. Google Play service account

The release workflow uploads to Play via the [Google Play Developer
Publishing API](https://developers.google.com/android-publisher).
Authentication uses a service account JSON key, not the developer's
personal Google credentials.

One-time setup:

1. In **Play Console** → Setup → API access → Choose a Google Cloud
   project (or link a new one). Accept the terms.
2. Click **Create new service account** — opens Google Cloud Console
   in a new tab.
3. In Cloud Console: IAM & Admin → Service Accounts → CREATE SERVICE
   ACCOUNT. Name it `scry-play-publisher`. No project-level roles
   needed.
4. On the new service account: Keys → ADD KEY → Create new key →
   JSON. Download the file. **Treat as a primary credential** — same
   sensitivity as the keystore password.
5. Back in Play Console's API access page, find the new service
   account row → **Grant access**. Permissions to grant:
   - Releases → Release apps to testing tracks: **Yes**
   - Releases → Release apps to production: No (we promote manually)
   - Releases → Manage testing tracks and edit tester lists: Yes
6. Paste the JSON file's content into the `PLAY_SERVICE_ACCOUNT_JSON`
   GitHub Actions secret.

### 5. Create the Play Console app entry

One-time. Use the same `applicationId` from `app/build.gradle.kts`
(currently `com.phaneronrobotics.scry`).

---

## Per-release flow

### 1. Bump version

Only `versionName` and `CHANGELOG.md` need touching:

```kotlin
// app/build.gradle.kts
versionName = "0.1.1" // human-readable; appears on the listing.
// versionCode is auto-derived from ``git rev-list --count HEAD``
// (see the helper at the top of the file). Don't hand-edit it.
```

Update `CHANGELOG.md` with a new `## [0.1.1] — YYYY-MM-DD` section
(the workflow extracts this and uses it as the "What's new" text on
the Play release).

Commit + merge to `master` via a normal PR. The merge itself bumps
`versionCode` for you (because it adds a commit to master, which
the auto-derivation counts).

### 2. Tag + push

```bash
git checkout master
git pull --ff-only
git tag v0.1.1
git push origin v0.1.1
```

The workflow fires within ~30 seconds.

### 3. Watch the workflow

```
https://github.com/phaneron-robotics/scry-android/actions/workflows/release.yml
```

Three jobs:
- `Build signed AAB` — ~3 min. Produces the `.aab` as a workflow artefact.
- `Publish to Play (Internal)` — ~1 min after build. Pushes to the
  Internal Testing track.
- `GitHub Release` — ~30 s after build. Creates the Release page.

Total wall time: ~5 min.

#### Dry-run mode (pre-flight)

Before your first real release — or any time you want to validate
that a change to the workflow itself didn't break anything — run the
workflow manually with `dry_run` set. Actions tab → Release →
**Run workflow** → fill in:

- `tag`: an existing tag, eg `v0.1.0`
- `dry_run`: **true** (this is the key)

That executes the **Build signed AAB** job only; the `Publish to
Play (Internal)` and `GitHub Release` jobs are skipped via their
`if:` guards. The AAB still lands as a workflow artefact so you can
download it, install on a phone, and confirm the signed build boots
before you flip dry_run off.

### 4. Verify on Internal track

1. Play Console → Testing → Internal testing → look for the new
   release with the matching versionCode.
2. The opt-in URL for testers is at the top of that page. Open it on
   the test phone (or share with testers) → "Become a tester" →
   install the latest version from Play Store.
3. Smoke-test on the phone for ~5 min. The AAB the testers see is
   exactly what Play will serve to production users after promotion
   — no separate build.

### 5. Promote to Production (when ready)

In Play Console → Testing → Internal testing → "Promote release" →
target Production. Fill in the rollout percentage (start at 20% or
50% for safety; bump to 100% after a day if crash-free is clean).

The first production release of a fresh app goes through a manual
review queue at Google (~1–7 days). Subsequent releases bypass the
review queue and roll out within ~hours.

---

## Troubleshooting

### Workflow: "decoded keystore is not a valid PKCS12 file"

The `SCRY_KEYSTORE_BASE64` secret was line-wrapped. Re-encode with
`base64 -w 0 ~/scry-upload.jks` (the `-w 0` is the key — disables
line wrapping). Paste the single-line result as the secret value.

### Workflow: "apksigner refused the AAB signature"

Either the keystore is wrong or the password is wrong. Verify
locally:

```bash
./gradlew :app:bundleRelease --no-daemon
# Then verify the produced AAB:
$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | sort -V | tail -1)/apksigner \
    verify --verbose app/build/outputs/bundle/release/*.aab
```

If local works but CI fails, the secret values in GitHub are off.
Re-add them.

### Play upload: "Version code N has already been used"

Shouldn't happen because `versionCode` is derived from
`git rev-list --count HEAD`, so every commit on master produces a
unique versionCode. If it does fire, either:

1. You're tagging a commit that's already been released (the same
   commit-count was used by a previous tag). Tag a different commit,
   or land one more commit on master to bump the count.
2. The CI runner cloned without git history (shallow clone) and the
   exec fell back to versionCode=1. Fix by ensuring `fetch-depth: 0`
   in the release workflow's checkout step.

Don't try to rewrite a published release with the same versionCode —
Play permanently rejects a versionCode it has already seen on any
track, even Internal. The "land one more commit" path is always
recoverable.

### Play upload: "Service account doesn't have permission"

The service account needs the "Release apps to testing tracks" and
"Manage testing tracks" permissions. See setup step 4.

### Play upload: "App must be created first"

The Play Console app entry doesn't exist for `com.phaneronrobotics.scry` yet. Create
it manually in Play Console first (one-time). Future releases reuse
the same package id.

### Local: `Keystore file 'scry-upload.jks' not found`

Either:
- `keystore.properties` has a relative path that doesn't resolve from
  the repo root. Use an absolute path.
- The keystore file moved. Update `keystore.properties` to match.

---

## Versioning policy

We follow semver. ``versionCode`` is **derived automatically** from
the master-branch commit count; you don't touch it. ``versionName`` is
the only field a release engineer edits in `app/build.gradle.kts`:

| Release | versionCode (auto) | versionName (hand-edit) |
|---|---|---|
| First release | N (= commit count at release time) | 0.1.0 |
| Patch bug-fix | N + 1 | 0.1.1 |
| Minor feature | N + few | 0.2.0 |
| Beta of 0.2.0 | N + few then N + few + 1 | 0.2.0-beta.1 then 0.2.0-beta.2 |

The auto-derivation lives in `app/build.gradle.kts` (the
``gitCommitCount`` helper at the top of the file). It uses Gradle's
``providers.exec`` so it plays nicely with the configuration cache;
falls back to ``1`` only when git isn't available (eg a downloaded
tarball without ``.git``).

Beta tags (`-beta.N`) are pushed only to the Internal track; real
`vX.Y.Z` tags are pushed to Internal and promoted to Production
after verification.
