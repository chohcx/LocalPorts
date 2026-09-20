#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift test
python3 scripts/verify_ui_contract.py
./scripts/build-app.sh
python3 scripts/verify_bundle.py dist/LocalPorts.app
python3 scripts/verify_layout.py dist/LocalPorts.app/Contents/MacOS/LocalPorts
python3 scripts/verify_jitter.py dist/LocalPorts.app/Contents/MacOS/LocalPorts
ARCHIVE="LocalPorts-1.1.0-macOS-Intel.zip"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --norsrc --keepParent dist/LocalPorts.app "dist/$ARCHIVE"
(cd dist && /usr/bin/shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256")
python3 scripts/verify_release.py
printf 'Release ready: dist/%s\n' "$ARCHIVE"
