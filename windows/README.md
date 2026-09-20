# LocalPorts for Windows

Native .NET 8 / Windows Forms TCP listener inspector for Windows 10/11 x64.

## Run

Download the `LocalPorts-windows-x64` artifact from a successful **Windows** GitHub Actions run. Extract the artifact ZIP, then extract `LocalPorts-windows-x64.zip`. Keep the entire `LocalPorts` folder together and run `LocalPorts.exe`. The self-contained build does not require installing .NET. No administrator access is requested.

The window opens on startup. **Minimize or close hides it without quitting.** The notification-area icon remains active: double-click to restore, or right-click for **Open LocalPorts** / **Quit**. Quit disposes the icon and refresh timer.

Windows decides whether the icon appears directly beside the clock or inside the **hidden icons / overflow** area. LocalPorts cannot force that choice. Use Windows 11 Settings → Personalization → Taskbar → Other system tray icons (wording varies by version), or Windows 10 Taskbar settings → Select which icons appear on the taskbar. Dragging the icon between the taskbar and overflow is also supported on applicable Windows versions.

## Features and safety

- Real IPv4 and IPv6 TCP listening endpoints from `GetExtendedTcpTable`, refreshed in a background task every three seconds. No PowerShell subprocess, WMI command-line collection, or synthetic process data.
- Search port, process, runtime hint, PID and binding. Select a row and toggle **Details** for CPU, working-set RAM, uptime, executable, owner and all bindings for that process.
- Runtime labels are process-name heuristics, not language detection. CPU is normalized across logical processors; first sample needs another refresh.
- Open/copy uses HTTP by default and HTTPS on port 443. Wildcard addresses map to loopback. Not every listener speaks HTTP; IPv6 scoped addresses may not be accepted by every browser.
- **Directory** and **Terminal** open the executable's directory, **not the process working directory**, which is not collected. Arguments and environment variables are never read or displayed.
- Stop requires current-user ownership and a matching creation timestamp. Ownership and start identity are revalidated against a retained process handle before action. Protected, inaccessible, system and self processes cannot be stopped.
- Windows has no general SIGTERM equivalent: after confirmation LocalPorts tries `CloseMainWindow`. Console services often cannot close this way. A separate, default-No confirmation is mandatory before `TerminateProcess`; unsaved work can be lost. Only the selected process is targeted, never a process tree.
- TCP only; UDP and remote-established connections are intentionally excluded. Inaccessible/exited processes remain visible with unavailable details. No elevation, autostart, persistence or telemetry.

The executable is **unsigned**. Windows SmartScreen may warn. Only run artifacts from a source you trust; inspect/build the source if uncertain. Signing and an installer are not included. MIT license inherited from the repository.

## Build and test

Install the .NET 8 SDK, then from the repository root:

```powershell
dotnet test windows/LocalPorts.Tests/LocalPorts.Tests.csproj -c Release
dotnet publish windows/LocalPorts/LocalPorts.csproj -c Release -r win-x64 --self-contained true -o windows/out/LocalPorts
$p = Start-Process windows/out/LocalPorts/LocalPorts.exe -ArgumentList '--smoke-test' -Wait -PassThru
if ($p.ExitCode -ne 0) { throw 'Smoke test failed; inspect smoke-error.txt' }
```

Core tests run on macOS/Linux as well. Cross-compilation is enabled, but the listener/NotifyIcon smoke test requires Windows. The smoke test spawns its own loopback TCP listener child, checks its port/PID/ownership, and exercises close, restore, minimize and quit on the actual form; it terminates only its own child in cleanup. It does not prove Windows Shell's visual overflow placement. Manually check that placement, double-click and context-menu interactions on a Windows desktop.

The shared `assets/brand/localports.ico` is embedded and copied when present; otherwise the standard application icon is used. CI publishes a self-contained folder ZIP and runs the Windows smoke test before upload.
