# Security

## Scope

LocalPorts 1.0.x is the current release line. Security fixes are provided on a best-effort basis; no response-time guarantee is made.

The app runs as the logged-in user, without privilege escalation. It invokes system tools for TCP listener and process metadata and reads working directories. It does not collect full command arguments or environments for display or diagnostics, and implements no telemetry or remote reporting.

Stopping a process requires confirmation (Cancel by default) and a matching UID and kernel-reported start identity. Only SIGTERM is sent. The final identity-check/signal race remains possible; this is not a privileged security boundary. Browser actions assume HTTP, and raw bindings can represent externally exposed services.

Downloaded builds are ad-hoc signed, not Developer ID signed or notarized. SHA-256 files protect against accidental corruption, not a compromised download source. Build from reviewed source when stronger provenance is needed.

## Reporting

Do not post credentials, real process dumps, home paths or exploit details in a public issue. Use GitHub's **Report a vulnerability** on the repository Security page if private reporting is enabled. If it is unavailable, open a minimal issue asking the maintainer for a private channel without disclosing sensitive details. Include affected version, macOS version, reproduction using synthetic data and expected impact once a private channel is established.
