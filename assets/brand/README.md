# LocalPorts identity

An original geometric socket: one quiet charcoal tile, a clear off-white enclosure, and two restrained blue contacts. The paired contacts suggest local connections without letters, tiny details, or borrowed system symbols. The broad silhouette stays recognizable at small sizes.

- `localports.svg` — editable vector source; 1024 × 1024 viewBox.
- `localports.png` — transparent 1024 × 1024 raster.
- `localports.icns` — macOS app icon, 16–1024 px representations.
- `localports.ico` — Windows icon, 16/24/32/48/64/128/256 px RGBA frames.

Palette: charcoal `#24282E`, off-white `#F4F6F8`, blue `#6AAEFF`. No gradients, shadows, fonts, or external artwork. The menu-bar template glyph and text-only panel header are deliberately unchanged.

## Regenerate and verify

On macOS, with the Swift command-line tools (no third-party packages):

```sh
swift scripts/build-icons.swift
python3 scripts/verify_icons.py
bash scripts/build-app.sh
python3 scripts/verify_bundle.py dist/LocalPorts.app
```

Run from the repository root. The native renderer reads the SVG's five rounded rectangles; it is intentionally not a general SVG engine. Edit those rectangles to keep generated formats in sync, then regenerate all assets. Temporary iconset files are removed after export. ICO uses PNG-compressed frames, supported by modern Windows.

## License

All artwork and generation scripts are original to LocalPorts and available under the repository's [MIT license](../../LICENSE).
