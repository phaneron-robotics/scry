# Security Policy

Phaneron Robotics, Inc. takes the security of Scry seriously. This
document describes how to report vulnerabilities and what to expect
in return.

## Reporting a vulnerability

**Do not open a public GitHub issue for security problems.**

Please report security issues privately through any of:

1. **GitHub Security Advisories** (preferred): on the affected repo,
   click `Security` → `Report a vulnerability`. This gives us a private
   collaboration thread tied to the right repo.
2. **Email**: [security@phaneronrobotics.com](mailto:security@phaneronrobotics.com)
   (monitored by the maintainers). For sensitive content, you can also
   email [deep@phaneronrobotics.com](mailto:deep@phaneronrobotics.com) directly.

Please include:

- A description of the vulnerability and its potential impact
- Steps to reproduce, ideally with a minimum proof of concept
- The affected component(s): `scry-connect`, `scry-android`,
  `scry-docs`, etc.
- The affected version(s) if known
- Any suggested mitigations or fixes

If your report contains exploitation details, consider attaching them as
an encrypted file rather than including them inline.

## What to expect

| Step | Target time |
|------|-------------|
| Initial acknowledgement | within 3 business days |
| Triage + severity assessment | within 7 business days |
| Fix in main + patched release | depends on severity (see below) |
| Public disclosure | coordinated with reporter, after fix ships |

Severity guidelines for fix timing:

- **Critical** (remote code execution on robot, auth bypass, secret
  disclosure): aim for fix within 7 days
- **High** (privilege escalation, data exposure on LAN): aim for fix
  within 30 days
- **Medium / Low**: bundled into the next normal release

We follow **coordinated disclosure**: once a fix is available, we
publish a GitHub Security Advisory crediting the reporter (with their
permission) and assign a CVE if applicable.

## Scope

In scope:

- `scry-connect` (Python MCP server running on robots)
- `scry-android` (Android app)
- `scry-ios` (when released)
- Default configurations and install scripts in `scry` /
  `robot-setup/`

Out of scope:

- ROS 2 itself (report to the ROS 2 project)
- DDS implementations (Fast-DDS, CycloneDDS, Connext, Zenoh)
- Third-party AI providers (Claude, OpenAI, Gemini, Ollama)
- User-deployed network infrastructure (their LAN setup, their reverse
  proxy)
- Issues that require physical access to an unlocked device

## Threat model

Scry is designed around a few core assumptions. Reports that fall
outside these assumptions are still welcome, but we may classify them
as hardening suggestions rather than vulnerabilities:

- **The Android phone runs in a single-user context.** A compromised
  Android user account already has access to whatever Scry can do; we
  protect against passive network adversaries on the LAN, not against
  rooted-phone adversaries.
- **The connect runs in a trusted ROS environment.** Anyone who can
  reach the connect's port is assumed to be authorized to talk to the
  ROS graph. Auth tokens prevent casual access but do not replace
  network segmentation.
- **All AI calls happen on the phone.** API keys never leave the
  device. Cloud AI providers can see prompts + tool results but never
  raw credentials.
- **Write operations require explicit user approval.** The phone
  enforces this UI even if the connect is misconfigured to skip it.

See `docs/SECURITY_AUDIT.md` (when published) for the full
threat-model analysis.

## Safe harbor

We will not pursue legal action against good-faith security research
that:

- Stops at proof of concept (no destructive testing on third-party
  systems)
- Respects user privacy (no accessing data that isn't yours)
- Gives us reasonable time to fix issues before public disclosure
- Doesn't exploit the issue beyond what's needed to demonstrate it

## Hall of fame

Researchers who report valid vulnerabilities will be credited (with
permission) in:

- The GitHub Security Advisory for the issue
- Release notes for the patched version
- This file's Hall of Fame section (TBD)

Thank you for helping keep Scry secure.
