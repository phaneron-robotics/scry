# Security Policy

Phaneron Robotics, Inc. takes the security of Scry seriously.

## Reporting a vulnerability

**Please don't open a public issue for security problems.**

Report privately through either:

1. **GitHub Security Advisories** (preferred): on this
   [`scry`](https://github.com/phaneron-robotics/scry) repo, go to
   `Security` → `Report a vulnerability`. The code repos are private, so
   this repo is the place to file all reports.
2. **Email**: [security@phaneronrobotics.com](mailto:security@phaneronrobotics.com).

Please include what the issue is, how to reproduce it, the affected
component (the Scry app, `scry-connect`, or the docs site), and the
version if you know it.

## What to expect

| Step | Target |
|------|--------|
| Acknowledgement | within 3 business days |
| Triage + severity | within 7 business days |
| Fix + patched release | by severity (critical ~7 days, high ~30 days, otherwise next release) |
| Disclosure | coordinated with you, after the fix ships |

We follow coordinated disclosure and will credit you (with your
permission) in the advisory and release notes.

## Scope

In scope: the Scry app, `scry-connect`, and the default install script
and configuration.

Out of scope: ROS 2 and DDS implementations, third-party AI providers
(OpenRouter and the models it routes to, or your local Ollama), your own
network setup, and issues that need physical access to an unlocked
device.

## Threat model

A few assumptions Scry is built on. Reports outside these are still
welcome, but may be treated as hardening suggestions:

- **The phone is single-user.** We protect against passive network
  adversaries on the LAN, not a rooted phone.
- **The connect runs in a trusted ROS environment.** Anyone who can
  reach its port is assumed authorized; auth tokens deter casual access
  but don't replace network segmentation.
- **AI calls happen on the phone.** API keys never leave the device.
- **Writes require explicit user approval** in the app.

## Safe harbor

We won't pursue legal action against good-faith research that stops at
proof of concept, respects privacy, and gives us reasonable time to fix
before disclosure.

Thank you for helping keep Scry secure.
