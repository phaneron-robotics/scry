# Install Scry on Android

Scry is in **closed beta** on Google Play. Two ways to get it on your phone:

## Option A — Play Store Internal Testing (recommended)

The Internal Testing track is private — only Google accounts on the
tester list can see the listing. To join:

1. **Send your operator the Google account email** you want to test with.
   It has to match the account signed in on the phone you'll install on.
   Personal Gmail or Google Workspace both work.
2. **Wait for confirmation** that you've been added (usually same day).
3. **Tap the opt-in URL** the operator sends you. The link looks like:

    ```
    https://play.google.com/apps/internaltest/<long-id>
    ```

4. Tap **Accept** on the "Become a tester" page.
5. **Install from the Play Store listing** you land on. Scry shows up
   in your library like any other app — updates ship automatically.

!!! note "Temporary app name"
    Until Google reviews the listing, Play Store displays the app as
    `com.phaneronrobotics.scry (unreviewed)`. Once reviewed, the display
    name flips to **Scry**. The app itself is the same either way.

## Option B — sideload the AAB from GitHub Releases

If you can't access the Play Store track, or you want to install on a
device without Play services, grab the AAB directly:

1. Go to [scry-android releases](https://github.com/phaneron-robotics/scry-android/releases).
2. Download `app-release.aab` from the latest release.
3. Convert AAB to a universal APK using
   [bundletool](https://github.com/google/bundletool):

    ```bash
    bundletool build-apks \
      --bundle=app-release.aab \
      --output=scry.apks \
      --mode=universal
    unzip -o scry.apks -d scry-apk
    adb install scry-apk/universal.apk
    ```

4. Enable **Install unknown apps** for whatever installer you used
   (Files, Drive, etc.) under **Settings → Apps → Special access**.

!!! warning "Auto-updates disabled"
    Sideloaded builds don't auto-update. You'll have to manually grab
    each release. Stick with Option A if you can.

## Verify the install

1. Open Scry from your app drawer.
2. Sign in with Google, GitHub, magic-link email, or password — or tap
   **Try Demo Mode** to skip sign-in and explore the app with simulated
   data (no robot required).
3. You should land on the empty-state chat screen with a "deep-dell"-
   style robot name placeholder.

You're ready to [install scry-connect on the robot](install-connect.md).
