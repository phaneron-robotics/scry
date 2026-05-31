# File attachments and images

Drop text logs, source files, or screenshots into the conversation.
Scry reads them along with your prompt.

## How to attach

In the chat composer (bottom of the Scry tab):

1. Tap the **+** icon (left of the mic).
2. Pick one of:
    - **Take photo** — opens the camera. Captures at full resolution,
      then auto-downscales to max 2048 px on the longest edge before
      sending.
    - **Gallery** — opens the Android Photo Picker. Pick one image.
    - **File** — opens the system file picker. Pick any text-ish file.
3. The attachment shows as a chip above the composer.
4. Type a question and send.

You can attach multiple files in one message. Up to **5 attachments
per turn**.

## Image attachments

| Limit | Value |
|---|---|
| Max dimension | 2048 px on the longest edge (auto-downscaled) |
| Format | JPEG, encoded base64 |
| Quality | 92 (high — preserves text in screenshots) |
| EXIF | Orientation auto-corrected (no sideways photos) |

Images are sent inline with your message to your chosen AI provider.
Their vision model sees them; Phaneron Robotics does not.

## File attachments

| Limit | Value |
|---|---|
| Max size | 1 MB (files over the cap are rejected with a warning, not truncated) |
| Format | Read as UTF-8 |
| Filename | Preserved — shown in the chip and inlined in the prompt |

The full text is inlined into the model prompt. The 1 MB cap is
deliberate — past it you're burning your context window without
proportional value, so trim or split the log before attaching.

## What gets stored

- **On your phone:** The attachment content stays in your chat history
  until you delete the message. Useful for re-reading without
  re-uploading.
- **On the AI provider:** Whatever your provider's retention is. Most
  default to zero retention; check your provider's policy.
- **Phaneron Robotics:** Nothing. Attachments never touch any Phaneron-
  controlled server unless you send them via Settings → Feedback.

## Common uses

- **Stack traces in `/rosout`** — paste the log file, ask "what's
  causing this?"
- **RViz screenshots** — "the robot is stuck at this waypoint; what
  do you see?"
- **URDF / launch files** — "explain what this launch file does"
- **`ros_doctor` output** — "any concerning warnings here?"
- **Photo of a wiring issue** — "the IMU isn't publishing; is this
  cable seated right?"

## Privacy reminder

Attachments are part of the conversation context. If you also tap thumbs down
on a reply that referenced the attachment, **only the user's preceding
prompt and tool names are sent to the feedback DB** — not the
attachment content. See [Sending feedback](feedback.md).
