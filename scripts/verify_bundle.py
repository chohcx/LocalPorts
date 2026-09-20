#!/usr/bin/env python3
import pathlib, plistlib, subprocess, sys
app = pathlib.Path(sys.argv[1])
assert app.is_dir(), 'Built app bundle is missing'
with (app/'Contents/Info.plist').open('rb') as f:
    info = plistlib.load(f)
assert info['LSMinimumSystemVersion'] == '13.0'
assert info['LSUIElement'] is True
exe = app/'Contents/MacOS/LocalPorts'
assert 'x86_64' in subprocess.check_output(['file', str(exe)], text=True)
subprocess.run(['codesign', '--verify', '--strict', str(app)], check=True)
subprocess.run([sys.executable, str(pathlib.Path(__file__).with_name('smoke.py')), str(exe)], check=True)
print('PASS: app bundle/macOS13/Intel/signature')
