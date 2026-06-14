---
hide:
  - navigation
  - toc
title: Scry — debug your ROS 2 robot from your phone
description: Scry is a mobile app that lets you debug any ROS 2 robot through an on-device AI assistant. Inspect topics, call services, and monitor diagnostics by voice, text, or image, over your own network. Your robot and chat data never route through a Scry server.
---

<div class="scry-hero" markdown>
<img src="assets/scry-mark.svg" alt="Scry logo — a stacked-bar s-curve mark on warm graphite, two olive accent bars" class="scry-hero__mark">
<h1 class="scry-hero__title">Scry<span class="scry-hero__title-accent">.</span></h1>
<p class="scry-hero__tagline">
Your ROS 2 robot, in your pocket. Debug topics, call services,
and monitor diagnostics by chatting with an on-device AI assistant.
</p>
<div class="scry-hero__actions">
  <a href="get-started/" class="md-button md-button--primary">Get started</a>
  <a href="how-it-works/" class="md-button">How it works</a>
</div>
<div class="scry-hero__badges">
  <a href="get-started/install-android/" class="scry-badge" aria-label="Get the Scry app on Google Play">
    <img src="assets/google-play-badge.svg" alt="Get it on Google Play">
  </a>
  <a href="https://pypi.org/project/scry-connect/" class="scry-badge" aria-label="Install scry-connect on your robot from PyPI">
    <img src="assets/pypi-badge.svg" alt="Install scry-connect on your robot from PyPI">
  </a>
</div>
</div>

<span class="scry-eyebrow">What is Scry</span>

Scry is a mobile app and a small robot server that together turn any
ROS 2 robot into something you can talk to. Ask a question in plain
English, by voice, or with a screenshot. Scry inspects your robot's
topics, nodes, services, parameters, and diagnostics live over your
network and answers with structured panels, plots, and links to deeper
views.

The phone does the work. The robot just exposes its ROS 2 graph. **Your
robot and chat data never route through a Scry server, and there's no
telemetry. Your AI key, your robot, your network.** A free account
(synced via Supabase) signs you in and stores your profile across
devices — see the [Privacy policy](legal/privacy.md).

---

<span class="scry-eyebrow">What you can do</span>

<div class="grid cards" markdown>

-   :material-chat-processing: **Debug by chatting**

    Ask in plain language — *"why isn't `/cmd_vel` publishing?"* — and
    Scry inspects topics, nodes, services, and parameters live, then
    explains what it found.

-   :material-microphone: **Voice and images**

    Talk to your robot hands-free, or attach a screenshot or photo and
    ask *"what's wrong in this scene?"* Transcription runs on your phone.

-   :material-gesture-tap-button: **Act with one tap**

    Publish a topic, set a parameter, call a service, drive a lifecycle
    change — every action shows you exactly what it'll do and waits for
    your approval first.

-   :material-bell-ring: **Background monitors**

    *"Alert me if the battery drops below 20%."* Scry watches a topic
    field in the background and pings you the moment the threshold trips.

-   :material-chart-line: **Live panels and plots**

    Sensor readouts, scene snapshots, transform trees, and live plots
    render right in the chat — no raw JSON to squint at.

-   :material-wifi-off: **Yours, end to end**

    Your robot and chat data never touch a Scry server, and there's no
    telemetry. Pair a local model and your conversations stay on your
    network. Your AI key, your robot, your network.

</div>

---

<span class="scry-eyebrow">How it works</span>

```mermaid
flowchart LR
    A["Scry app\non your phone"]
    B["scry-connect\non your robot"]
    C["ROS 2 graph\nany middleware"]
    A <-->|"your network"| B
    B <-->|"ROS 2"| C
    classDef brand fill:#292826,stroke:#3A3835,stroke-width:1px,color:#E8E4D9
    class A,B,C brand
    linkStyle 0,1 stroke:#A3B86C,stroke-width:2px,color:#9C9A8D
```

Your phone runs the assistant, decides what to check, renders the
results, keeps your monitors running, and manages your fleet. The robot
runs a small server, `scry-connect`, that exposes its ROS 2 capabilities
to Scry. Reads are free; anything that changes the robot asks for your
approval first. [Read more →](how-it-works.md)

---

<span class="scry-eyebrow">What you need</span>

- **A phone** running Android 9 or newer. (iOS coming soon.)
- **A ROS 2 robot** running Humble, Jazzy, Kilted, Lyrical, or Rolling.
- **An AI provider.** OpenRouter is recommended — one key unlocks 300+
  models and has a free tier. Prefer fully offline? Point Scry at a
  local Ollama server. See [Choose your AI](get-started/choose-ai.md).
- **A free Scry account.** Sign in with Google, GitHub, or email to
  sync your profile across devices. Your robot and chat data still flow
  directly — only your profile lives on our server.
- **Your network.** Phone and robot talk directly. Your robot data never
  routes through a Scry cloud.

---

<span class="scry-eyebrow">Where to go next</span>

<div class="grid cards" markdown>

-   **Get started**

    Get the app, run `scry-connect` on the robot, choose your AI, pair,
    and ask your first question. About fifteen minutes end to end.

    [Get started](get-started/index.md)

-   **Use Scry**

    Chat with Scry, attach logs and images, set background monitors,
    and connect to your robot from anywhere.

    [Use Scry](use/index.md)

-   **How Scry works**

    The phone does the thinking, the robot just runs a small server.
    Why your robot data never routes through a Scry cloud, and how
    actions stay safe.

    [How Scry works](how-it-works.md)

-   **Reference**

    Everything Scry can inspect and do on a robot, and the phone
    permissions the app uses.

    [Reference](reference/index.md)

-   **Legal**

    Privacy policy, Play Store Data Safety, security policy, and
    license.

    [Legal](legal/index.md)

</div>

---

Maintained by [Phaneron Robotics, Inc.](https://www.phaneronrobotics.com/)
