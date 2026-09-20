#!/usr/bin/env python3
"""Validate the shipped archive, not only the pre-archive build."""
import hashlib
import pathlib
import plistlib
import subprocess
import tempfile
import zipfile

root = pathlib.Path(__file__).resolve().parent.parent
archive = root / 'dist/LocalPorts-1.1.0-macOS-Intel.zip'
assert archive.is_file(), 'Release ZIP is missing'
checksum = archive.with_suffix('.zip.sha256')
assert checksum.read_text().strip() == hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name
with zipfile.ZipFile(archive) as package:
    names = package.namelist()
    assert names and all(name.startswith('LocalPorts.app/') for name in names)
    assert not any('..' in pathlib.PurePosixPath(name).parts or '.DS_Store' in name for name in names)
with tempfile.TemporaryDirectory(prefix='localports-release-') as temporary:
    subprocess.run(['/usr/bin/ditto', '-x', '-k', str(archive), temporary], check=True)
    app = pathlib.Path(temporary) / 'LocalPorts.app'
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    assert info['CFBundleShortVersionString'] == '1.1.0'
    assert info['CFBundleVersion'] == '2'
    assert info['LSMinimumSystemVersion'] == '13.0'
    assert info['CFBundleDevelopmentRegion'] == 'en'
    assert info['LSUIElement'] is True
    executable = app / 'Contents/MacOS/LocalPorts'
    assert subprocess.check_output(['/usr/bin/lipo', '-archs', str(executable)], text=True).strip() == 'x86_64'
    subprocess.run(['/usr/bin/codesign', '--verify', '--strict', str(app)], check=True)
    assert b'/Users/' not in executable.read_bytes(), 'Release must not expose builder home paths'
    commands = subprocess.check_output(['/usr/bin/otool', '-l', str(executable)], text=True)
    assert 'minos 13.0' in commands, 'Mach-O deployment target must match bundle metadata'
    assert (app / 'Contents/Resources/LICENSE').is_file()
print('PASS: release ZIP/checksum/extracted signature/version/English/Intel/macOS13/license')
