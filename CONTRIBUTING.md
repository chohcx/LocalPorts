# Contributing

Small, focused pull requests are welcome. Discuss substantial behavior or UI changes in an issue first. Use English for app-owned strings and project documentation.

## Development

Use macOS 13+, Swift 5.9+ and Python 3. Run the build and test commands in the README. Write a failing regression test before changing behavior. Preserve the fixed panel, 330 pt viewport, compact header, neutral action hover, Reduce Motion support and stable listener identities. Do not relax geometry thresholds to make a test pass.

Keep process inspection read-only except for explicit, confirmed termination. Never test termination against an existing user service; use a disposable subprocess. Preserve default Cancel, UID/start-identity validation and SIGTERM-only behavior.

## Manual GUI checklist

In an interactive macOS session, test light/dark appearance, search, developer filter and Quit from Options, whole-row disclosure and keyboard activation, hover/press feedback and Reduce Motion. Confirm expansion/search/polling never resize or move the header, and scroll to overflow actions. Using your own disposable server, check browser/copy/Finder/new Terminal actions and that Cancel/Escape do not stop it. Only explicitly approve SIGTERM for that disposable server.

Automated native evidence is not a substitute for these manual checks. GUI scripts create synthetic captures and JSON under ignored `artifacts/`; diagnostics can contain private data. Never commit real process snapshots, home directories, credentials or developer logs. Public screenshots must use the synthetic `/example/` fixtures.

## Releases

Run `./scripts/release.sh` on an Intel macOS machine in a GUI login session. It builds version 1.0.0, runs the regression suite, verifies bundle metadata/signatures, archives using `ditto --keepParent`, and validates the extracted ZIP and checksum. Update version metadata and its assertions together for later releases. Upload only the ZIP/checksum as release assets, not generated build trees. Signing is ad-hoc; do not describe releases as notarized.

Contributions are licensed under the project's MIT License. Do not add third-party artwork or code without appropriate licensing and attribution.
