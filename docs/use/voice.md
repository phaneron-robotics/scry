# Voice input

Talk to your robot. Scry uses your phone's built-in speech recognition
to turn what you say into a message.

## How to use

1. Tap the **microphone** icon in the chat composer (between the `+`
   and the send button).
2. Your phone's speech-recognition dialog opens ("Speak now"). Say your
   question.
3. When you stop speaking, the dialog closes and Scry **sends the
   recognised text as your message** automatically.

The recognition UI is the one your phone provides, so it looks like the
voice input you already use elsewhere on the device.

!!! tip "Prefer to review before sending?"
    Voice sends as soon as recognition finishes. If you want to check or
    tidy a transcript first — handy for topic names with slashes and
    underscores — type it in the composer instead, or dictate using your
    keyboard's mic key, which drops text into the composer without
    sending.

## Permissions

The first time you use voice, your phone's speech-recognition service
asks for the **microphone** permission (Scry also declares it). Deny it
and the mic button stays inert with a toast on subsequent taps.

You can manage this anytime under Settings → Permissions in the app,
or in Android Settings → Apps → Scry → Permissions.

## Where the audio goes

Voice uses your phone's built-in speech-recognition service. Depending
on your phone and its settings, recognition may run **on-device** or be
handled by the platform's speech service; that's controlled by Android,
not by Scry.

Scry doesn't capture or send audio itself — it hands off to the system
recognizer and only ever receives the final **text**, exactly as if
you'd typed it.

## When voice fails

??? failure "Mic button is greyed out / inert"
    Microphone permission denied. Go to Settings → Permissions →
    Microphone → tap to open Android's permission page → allow.

??? failure "Transcript is wildly wrong"
    Because voice sends as soon as recognition finishes, a misheard
    message goes straight to Scry. A few things to try:

    - Speak in shorter chunks — long monologues compound errors
    - Pause briefly between technical terms — "ros — topic — list"
      transcribes better than "rostopiclist"
    - Type robot/topic names instead of saying them — recognizers are
      weak on terms with slashes and underscores. If a transcript lands
      wrong, just send a follow-up correction or retype it.

??? failure "Nothing happens when I tap the mic"
    Your phone may not have a speech-recognition service available
    (some Android variants without Google services, or custom ROMs).
    Scry shows a toast in that case — use the keyboard instead.
