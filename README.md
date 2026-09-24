# LocalPorts

A lightweight macOS menu-bar app for finding local TCP ports and the processes using them.

**macOS 13+ · Intel (x86_64) · MIT · No third-party dependencies**

## Windows (preview)

Download **[LocalPorts-windows-x64.zip](https://github.com/chohcx/LocalPorts/releases/download/v1.1.1/LocalPorts-windows-x64.zip)**, extract the entire folder, then run **LocalPorts.exe**. Windows 10/11 x64; the .NET runtime is included.

By default, only recognized developer runtimes are shown. Enable **Show all** to include system and other applications. Each process/port appears once, with its IPv4/IPv6 bindings in Details. Custom-named development executables may require **Show all**.

Closing or minimizing the window keeps LocalPorts in the notification area. Double-click its tray icon to restore it; right-click → **Quit** to exit. Windows controls whether the icon appears directly or inside the **hidden-icons (^)** flyout; adjust Taskbar settings or drag it as desired.

The Windows build is unsigned and may trigger SmartScreen. Only run trusted downloads. This is an initial Windows implementation, not visual parity with the macOS panel. Windows CI verifies listener discovery and tray lifecycle; desktop appearance and real Explorer interaction still need manual testing. See the [Windows guide](windows/README.md) for safety differences and build instructions.

## Download and open (macOS)

1. Download **[LocalPorts-1.1.0-macOS-Intel.zip](https://github.com/chohcx/LocalPorts/releases/download/v1.1.0/LocalPorts-1.1.0-macOS-Intel.zip)** from [Releases](https://github.com/chohcx/LocalPorts/releases/latest).
2. Unzip it and drag **LocalPorts.app** into **Applications**.
3. Double-click **LocalPorts.app** to launch.
4. Click its **icon and port count in the macOS menu bar**. There is no Dock icon.

### First launch: if macOS blocks the app

LocalPorts is ad-hoc signed, **not Developer ID signed or notarized by Apple**. macOS may say that the developer cannot be verified or that Apple cannot check the app for malicious software. This means Apple has not verified this release; it is not a guarantee that the app is safe. Only proceed if you trust this repository and downloaded the app from its Releases page.

1. Try opening **LocalPorts.app** once, then dismiss the warning without moving the app to the Trash.
2. Open **Apple menu → System Settings → Privacy & Security**.
3. Scroll to **Security** and find the message about LocalPorts being blocked. Click **Open Anyway**, if offered.
4. Authenticate on your Mac if prompted, then click **Open** in the confirmation dialog.
5. Look for LocalPorts in the **menu bar**, not the Dock. Approval is normally remembered for that copy of the app; a new download or update may prompt again.

If **Open Anyway** is missing, try opening the app again and return to this settings page. A managed Mac may require your administrator's approval. If macOS specifically reports malware or that the app will damage your computer, stop rather than bypassing the warning. Do not disable Gatekeeper globally or run quarantine-removal commands.

Apple Silicon is not a tested release target.

Optional checksum verification: download the matching `.sha256` file into the same folder as the ZIP, then run:

```sh
shasum -a 256 -c LocalPorts-1.1.0-macOS-Intel.zip.sha256
```

## Launch from Terminal

After installing in Applications:

```sh
open -a LocalPorts
```

Prefer typing **`LP`**? Add this line to `~/.zshrc` (the default macOS shell), then open a new Terminal window:

```sh
alias LP='open -a LocalPorts'
```

You can then launch the app with:

```sh
LP
```

`LP` is an optional shell alias, not an automatically installed command. It opens the same menu-bar app, not a separate terminal interface. To try it only in the current Terminal, run the alias line there without editing `~/.zshrc`.

## Use LocalPorts

- **Browse:** See each port, project/process name, runtime, uptime, CPU and memory.
- **Search:** Filter by name, project, PID, address or port.
- **Expand a row:** Click anywhere on it to view details and action buttons. Scroll for more entries.
- **Take action:** Open an HTTP URL, copy it, reveal the working directory in Finder, or open a new Terminal window there. Hover over an icon for its label.
- **Stop a process:** Click the stop icon and confirm. This sends SIGTERM to the entire owned process, including its other ports; unsaved work may be lost.
- **Filter or quit:** Use the top-right **Options** menu.

Updates happen quietly about every **2 seconds while open** and **10 seconds while closed**. No setup, administrator access or login item is required.

### Binding vs. Endpoint

**Binding** is the actual listening address; **Endpoint** is a convenient host-and-port address for connecting from your Mac.

For example, `Binding: *` can display `Endpoint: localhost:3000`. The wildcard means all applicable local interfaces—not localhost-only access. Specific IP addresses are preserved where applicable.

URL actions assume **HTTP**. LocalPorts cannot infer HTTPS, custom domains, reverse-proxy routes or tunnel URLs from a listening port. It lists TCP listeners visible to your account, not UDP services. Inspection stays local, with no telemetry; see [Security and privacy](SECURITY.md).

## Build from source

Requires macOS 13+, Xcode or Command Line Tools with Swift 5.9+, and Python 3 for verification.

```sh
git clone https://github.com/chohcx/LocalPorts.git
cd LocalPorts
swift test
./scripts/build-app.sh
open dist/LocalPorts.app
```

To use `open -a LocalPorts` or the `LP` alias with this build, first copy `dist/LocalPorts.app` to Applications. To produce a verified ZIP and checksum, run `./scripts/release.sh` in an interactive macOS login session.

See [Contributing](CONTRIBUTING.md) for development and testing. Diagnostic output may contain private process and directory names; review it before sharing.

Independent implementation inspired by [Ports](https://www.ports-app.com/); not affiliated with its authors. No Ports code or artwork is included. Icons use system SF Symbols at runtime.

[MIT License](LICENSE)
