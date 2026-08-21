# Shape Generator

An interactive Flutter developer tool that converts raw SVG path data into production-ready Flutter `CustomClipper` code — instantly, with a live preview.

## What It Does

Paste any SVG `<path>` element or raw path string into the editor, and the app instantly generates a fully typed Dart `CustomClipper<Path>` class you can drop directly into your Flutter project. No manual path parsing, no math — just copy, paste, and clip.

## Key Features

- **Smart SVG Parsing** — Accepts full `<svg>` markup or bare `<path>` strings. Handles both single-path and multi-path SVG shapes (`SvgClipper` & `MultiPathCardClipper`).
- **Live Shape Preview** — See your clipped shape rendered in real time with a customizable solid color or gradient fill, so you know exactly what the output will look like.
- **Responsive Code Generation** — Toggle between responsive (scaled to widget size) and fixed-dimension output. Choose between scale-factor and transform-matrix strategies.
- **Custom Preview Dimensions** — Adjust preview container width and height via sliders, or lock to the SVG's original intrinsic dimensions.
- **Three View Modes** — Switch between **Code**, **Preview**, and **Split** views to suit your workflow.
- **One-Tap Copy** — Copy the generated Dart code to clipboard from the AppBar with a single tap.
- **Web Support** — Runs natively in the browser via Flutter Web, making it accessible without any install.

## Tech Stack

- **Flutter + Dart** — Cross-platform UI
- **`path_drawing`** — SVG path parsing via `parseSvgPathData`
- **`CustomClipper<Path>`** — Native Flutter clipping for pixel-perfect shapes
- **Matrix4 transforms** — Precise scaling and translation of SVG coordinates to widget bounds

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on a connected device
flutter run
```

## Who Is It For?

Flutter developers who work with custom shapes, branded card designs, or complex UI clipping and want to skip the tedious boilerplate of converting SVG coordinates into Dart path operations by hand.
