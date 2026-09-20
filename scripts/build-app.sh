#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export MACOSX_DEPLOYMENT_TARGET=13.0
swift build -c release --arch x86_64
BIN="$(swift build -c release --arch x86_64 --show-bin-path)/LocalPorts"
APP="$PWD/dist/LocalPorts.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp LICENSE "$APP/Contents/Resources/LICENSE"
cp "$BIN" "$APP/Contents/MacOS/LocalPorts"
# Remove debug-map symbols containing absolute builder paths before signing.
/usr/bin/strip -S "$APP/Contents/MacOS/LocalPorts"
/usr/bin/python3 - "$APP" <<'PY'
import pathlib, plistlib, sys
app = pathlib.Path(sys.argv[1])
info = dict(CFBundleDevelopmentRegion='en', CFBundleName='LocalPorts', CFBundleDisplayName='LocalPorts', CFBundleIdentifier='local.localports.app', CFBundleVersion='1', CFBundleShortVersionString='1.0.0', CFBundleExecutable='LocalPorts', CFBundlePackageType='APPL', LSMinimumSystemVersion='13.0', LSUIElement=True, NSHighResolutionCapable=True)
with (app/'Contents/Info.plist').open('wb') as f:
    plistlib.dump(info, f)
PY
if command -v codesign >/dev/null; then
    codesign --force --sign - "$APP"
    codesign --verify --strict "$APP"
fi
printf 'Built: %s\n' "$APP"
