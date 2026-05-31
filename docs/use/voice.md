# Voice input

Talk to your robot. Scry transcribes locally and you tap send.

## How to use

1. Tap the **microphone** icon in the chat composer (between the `+`
   and the send button).
2. The button enlarges and shows a live waveform. Speak.
3. Release / tap again to stop.
4. The transcript appears in the composer text box.
5. Edit if needed, then tap **Send**.

## Why tap-to-send instead of auto-send

The transcript step is a quality gate. SpeechRecognizer occasionally
mishears domain terms ("`amcl`" → "Amazon", "`tf2`" → "to" twice).
Letting you read and edit before send is one second of friction in
exchange for not chasing transcription artifacts in your conversation
history.

## Permissions

First tap asks for the **microphone** runtime permission. Android shows
the standard "Allow Scry to record audio?" dialog. Deny and the mic
button stays inert with a toast on subsequent taps.

You can manage this anytime under Settings → Permissions in the app,
or in Android Settings → Apps → Scry → Permissions.

## Where the audio goes

Voice uses Android's built-in speech recognition. On most modern phones
(Pixels and Samsungs from 2022 onward) recognition runs **fully
on-device**; on older phones it may fall back to a Google network call.

Scry doesn't send audio anywhere itself. Scry only ever sees the final
text transcript, exactly as if you'd typed it.

## When voice fails

??? failure "Mic button is greyed out / inert"
    Microphone permission denied. Go to Settings → Permissions →
    Microphone → tap to open Android's permission page → allow.

??? failure "Transcript is wildly wrong"
    A few things to try:

    - Speak in shorter chunks — long monologues compound errors
    - Pause briefly between technical terms — "ros — topic — list"
      transcribes better than "rostopiclist"
    - Type robot/topic names instead of saying them — recognizer
      models are weak on terms with slashes and underscores

??? failure "No transcript appears at all"
    Google's SpeechRecognizer service may be disabled or
    uninstallable on some Android variants (Huawei devices without
    GMS, custom ROMs). Use the keyboard instead.
