# Operator

Runbooks the Phaneron team uses internally. If you're forking Scry or
running your own deployment, these tell you how to keep it on the
rails.

- **[Beta testing program](testing.md)** — how to add testers to the
  Play Console Internal track, what to send them, how to triage
  feedback.
- **[Release runbook](release-runbook.md)** — end-to-end procedure
  for cutting a release (tag → CI → Play Internal → manual promotion
  to Production).
- **[Security audit](security-audit.md)** — static + dependency
  audit notes for both the Android app and the Python connect.

## When to read these

- **Beta testing** — read before sending tester invites.
- **Release runbook** — read once before your first release. After
  that, the per-release flow is just `git tag vX.Y.Z && git push --tags`.
- **Security audit** — read pre-release to validate, and after any
  major dependency bump.
