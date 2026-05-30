# Pair the phone and robot

Once `scry-connect` is running on the robot and the Scry app is installed
on your phone, pairing takes about 30 seconds.

## Option A — Scan the QR code

The fastest path. Works whenever the phone and robot are on the same WiFi.

1. On the robot, the install script (or `scry-connect pair --print-qr`)
   printed a QR code in the terminal. Keep it visible.
2. Open Scry on your phone → tap the **Fleets** tab (bottom-left).
3. Tap **+ Add robot** → **Scan QR**.
4. Point the phone at the terminal until the QR is in frame. The app
   auto-detects, confirms, and connects. Should take under 2 seconds.

That's it. The connection status dot turns green and the chat header
shows the robot's name and its round-trip latency.

## Option B — Manual entry

If the QR path isn't convenient (headless robot, can't see the terminal):

1. On the robot, find its LAN IP:

    ```bash
    hostname -I | awk '{print $1}'
    # e.g. 10.0.0.89
    ```

2. In the Scry app: Fleets → **+ Add robot** → **Enter manually**.
3. Fill in:

    | Field | Value |
    |---|---|
    | Name | Anything — appears in chat. Use the robot's friendly name. |
    | Host | The IP from step 1, e.g. `10.0.0.89` |
    | Port | `5339` (default — only change if you ran `scry-connect --port`) |
    | Token | Leave blank unless you started the connect with `--token` |

4. Tap **Save** → **Connect**.

## Option C — LAN scan (last resort)

If you don't know the robot's IP and you can't see the QR:

1. Make sure phone and robot are on the same WiFi.
2. Fleets → **+ Add robot** → **Scan WiFi for scry-connect**.
3. The app probes the local `/24` for hosts answering on `:5339`.
4. Tap the robot when it appears in the list.

LAN scans take 10–30 seconds depending on the subnet size and how
many devices are online.

## What pairing does

A successful pair stores three things in the app's local DB:

- The robot's **name** (display only)
- The robot's **IP** and **port** (used for every MCP call)
- The optional **shared token** (sent in the `X-Scry-Token` header
  on every request, when set)

Pairing data is **per-device**. Re-installing the app or switching to a
different phone means re-pairing.

## Multiple robots

You can pair as many robots as you want. The Fleets tab lists all of
them with a green/orange/red status dot showing live connection health.
Tap a robot to switch the chat's "active" target.

## Health check

Once paired, the chat header shows:

```
deep-dell · 33ms
●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

The number is the round-trip latency on the last health probe. Under
50 ms is normal on a good WiFi. Over 500 ms means the robot is busy or
the WiFi is congested.

If the dot is **red**, the connect isn't reachable. Common causes:

- The robot is asleep or off
- WiFi router rebooted and assigned a different IP
- `scry-connect` service stopped (check on the robot: `systemctl --user status scry-connect`)

## Next

Robot is paired. Time for your [first debugging session](first-session.md).
