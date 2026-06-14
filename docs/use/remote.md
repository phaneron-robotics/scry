# Connect from anywhere

Scry connects your phone to `scry-connect` on the robot. By default that
happens over your local network, but you can also reach the robot
remotely. This page covers the connection options and the most common
ways to run the connect server.

## On the same network (default)

The normal setup: phone and robot on the **same Wi-Fi or LAN**. The
connect advertises itself automatically, so the app discovers nearby
robots without any configuration. You can also pair by scanning the QR
code the connect prints, or by typing the robot's IP address into the
app.

This is the recommended path for everyday use — it's the simplest and
the most secure, because the robot is never exposed beyond your network.

## From outside the network (remote)

`scry-connect` only accepts connections from private network addresses
by default — it deliberately refuses calls from the public internet so a
robot is never accidentally exposed. To use Scry away from the robot's
network, the recommended approach is to put your **phone and robot on the
same virtual network** with a VPN or tunnel:

- **Tailscale** or **WireGuard** — both place your devices on one
  private network, wherever they physically are, with no router setup or
  port-forwarding. Once both are on the VPN, Scry connects exactly as if
  they were on the same Wi-Fi. This is the easiest and safest option.
- **SSH tunnel** — for occasional access, forward the connect's port
  over SSH from a machine that can already reach the robot.

!!! warning "Exposing the connect directly is advanced"
    You *can* make `scry-connect` reachable from the public internet, but
    doing so means anyone who can reach the port could drive your robot.
    If you go this route, never do it in the default open mode — require
    a paired token (`--token`), and ideally terminate TLS with client
    certificates (`--mtls`) behind a reverse proxy. Even then, a VPN is
    the safer choice. Only expose the connect directly if you fully
    understand the risk.

## Running the connect server

After installing (see
[Install scry-connect on the robot](../get-started/install-connect.md)),
`scry-connect` runs with sensible defaults. These options cover the
common cases.

### Network and port

```bash
scry-connect --port 5339      # listen on a different port (default 5339)
scry-connect --host 0.0.0.0   # bind address (default 0.0.0.0)
scry-connect --no-mdns        # turn off automatic discovery on the network
```

The same settings can be provided as environment variables —
`SCRY_PORT`, `SCRY_HOST`, and `SCRY_MDNS=0` — which is handy in service
files and containers. `ROS_DOMAIN_ID` is honored as usual.

### Pairing and tokens

```bash
scry-connect pair             # show a pairing QR code for the app
scry-connect --token          # require a paired token on every request
scry-connect --print-qr       # reprint the current pairing QR
scry-connect --print-token    # print the current token and exit
```

Token mode is the right choice whenever the robot is reachable beyond a
trusted LAN. In token mode, Scry also confirms each action with a
one-time approval code in addition to your tap on the phone.

### Production hardening

```bash
scry-connect --mtls                       # require TLS client certificates
scry-connect --require-deadman            # block actions unless a deadman
                                          #   switch is actively held
scry-connect --audit-log /var/log/scry/audit.jsonl   # log every write (acting) tool call
```

`--mtls` expects TLS to be terminated by your reverse proxy.
`--require-deadman` refuses any action unless an enable signal has been
published within the last second — useful for tele-operation safety. The
audit log records every **write/acting** tool call (the source IP, the
tool and its arguments, and the outcome — e.g. `ok`, `rejected_no_confirm`,
`deadman_stale`); read-only tools are not audited.

## Verifying a connection

On the robot you can confirm the connect is up and see its current mode:

```bash
curl -s http://localhost:5339/health
```

A healthy server reports its status, the number of available tools, the
authentication mode, and the ROS distro it's running against. If you can
reach that from the phone's network, the app will connect.
