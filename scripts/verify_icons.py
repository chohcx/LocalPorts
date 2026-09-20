#!/usr/bin/env python3
"""Validate committed icon containers without third-party dependencies."""
import pathlib
import struct
import zlib
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
BRAND = ROOT / 'assets/brand'

def png_size(data):
    assert data[:8] == b'\x89PNG\r\n\x1a\n', 'Not a PNG'
    offset, dimensions, ended = 8, None, False
    while offset < len(data):
        length, kind = struct.unpack_from('>I4s', data, offset)
        payload = data[offset + 8:offset + 8 + length]
        crc, = struct.unpack_from('>I', data, offset + 8 + length)
        assert zlib.crc32(kind + payload) & 0xffffffff == crc, 'PNG CRC mismatch'
        if kind == b'IHDR':
            dimensions = struct.unpack_from('>II', payload)
            assert payload[9] == 6, 'Expected RGBA PNG'
        offset += 12 + length
        if kind == b'IEND':
            ended = True
            break
    assert ended and offset == len(data), 'Truncated/trailing PNG data'
    return dimensions

svg = ET.parse(BRAND / 'localports.svg').getroot()
assert svg.attrib['viewBox'] == '0 0 1024 1024'
assert png_size((BRAND / 'localports.png').read_bytes()) == (1024, 1024)
ico = (BRAND / 'localports.ico').read_bytes()
reserved, kind, count = struct.unpack_from('<HHH', ico)
assert (reserved, kind, count) == (0, 1, 7)
sizes = set()
expected_offset = 6 + count * 16
for i in range(count):
    w, h, colors, reserved, planes, depth, length, offset = struct.unpack_from('<BBBBHHII', ico, 6 + i * 16)
    w, h = w or 256, h or 256
    assert (planes, depth) == (1, 32)
    assert offset == expected_offset and offset + length <= len(ico)
    assert png_size(ico[offset:offset + length]) == (w, h)
    sizes.add(w)
    expected_offset += length
assert sizes == {16, 24, 32, 48, 64, 128, 256} and expected_offset == len(ico)
icns = (BRAND / 'localports.icns').read_bytes()
assert icns[:4] == b'icns' and struct.unpack_from('>I', icns, 4)[0] == len(icns)
offset, chunks = 8, set()
while offset < len(icns):
    kind, length = struct.unpack_from('>4sI', icns, offset)
    assert length > 8 and offset + length <= len(icns)
    chunks.add(kind)
    offset += length
assert offset == len(icns) and {b'ic07', b'ic08', b'ic09', b'ic10'} <= chunks
print('PASS: SVG, RGBA 1024 PNG, 7 ICO frames, complete ICNS container')
