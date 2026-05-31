# Choose your AI

Scry's assistant is powered by an AI model. You bring your own — Scry
doesn't resell AI or route your conversations through a Scry server.
There are two ways to provide one, both set up under
**Settings → AI providers**:

| Provider | Where it runs | Cost | Choose it when… |
|----------|---------------|------|-----------------|
| **OpenRouter** *(recommended)* | Cloud | Free open-weight models, or pay-per-use for premium ones | You want one key that unlocks hundreds of models and the best quality. |
| **Ollama** | On your own hardware | Free | You want to run fully offline, on an air-gapped robot, or keep everything on your network. |

OpenRouter is the default and the simplest place to start: a single key
gives you access to 300+ models — including Claude, GPT, Gemini, Llama,
and Qwen — and there's a free tier so you can begin without spending
anything.

## Option A — OpenRouter (recommended)

One API key, 300+ models, a free tier to start. You pick the specific
model from the model chip at the top of the chat screen, and you can
switch models at any time.

### Recommended models

Scry works by calling tools on your robot, so the model you pick must
support **tool calling**. If you attach photos or ask Scry to read a
camera frame, it also needs **vision**. Three good starting points:

| For… | Model | Notes |
|------|-------|-------|
| **Best free, general use** | `openai/gpt-oss-120b:free` | The default. Free, reliable, no credit card. Text only. |
| **Best free, with images** | `google/gemma-4-26b-a4b-it:free` | Free and multimodal — handles text *and* images and supports tool calling. Use it when you attach photos or inspect camera frames. |
| **Best paid, deepest reasoning** | `anthropic/claude-haiku-4-5` | Fast, inexpensive, excellent at multi-step diagnosis. |

!!! tip "Picking your own model"
    Browse the full catalogue at
    [openrouter.ai/models](https://openrouter.ai/models). Filter to
    **Free**, and check that a model lists **tools** support (and image
    input, if you need it). Any model that does will work in Scry.

### Set it up

1. In the app, open **Settings → AI providers → OpenRouter**.
2. Tap **Sign up** to create a free OpenRouter account at
   [openrouter.ai](https://openrouter.ai). No credit card is needed for
   the free tier.
3. Tap **Get API key**, create a key at
   [openrouter.ai/keys](https://openrouter.ai/keys), and copy it.
4. Paste the key into **OpenRouter API key** and save.
5. Open the model chip at the top of the chat screen and pick a model —
   start with the free default above.

## Option B — Ollama (local, offline)

Ollama runs AI models on your own machine — the robot itself or any
computer on the same network. Nothing leaves your network, there's no
API key, and it's free. The trade-off is that local models generally
reason less sharply than the cloud options and may occasionally need a
retry, but they're a great fit for offline or air-gapped robots.

### Set it up

1. Install Ollama on the robot or any host on your network — see
   [ollama.com/download](https://ollama.com/download).
2. Download a model that supports tool calling (add a vision model if
   you want image support):

    ```bash
    ollama pull qwen2.5:7b      # good general model with tool support
    ollama pull qwen2.5-vl      # optional: adds image/vision support
    ```

3. Make Ollama reachable on your network, not just locally:

    ```bash
    OLLAMA_HOST=0.0.0.0:11434 ollama serve
    ```

4. In the app, open **Settings → AI providers → Ollama**. Leave **Base
   URL** blank to let Scry find Ollama automatically on your network
   (it checks the robot's host on port `11434` first), or enter the
   address yourself, e.g. `http://192.168.1.50:11434`.
5. Pick the model you downloaded from the chat model chip.

## Switching models

You can change provider or model at any time from the **model chip** at
the top of the chat screen — even mid-conversation. The choice is
remembered on your device. Your API keys are stored encrypted on the
phone and are only ever sent to the provider you chose.
