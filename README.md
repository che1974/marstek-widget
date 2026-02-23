# Marstek Monitor

macOS menu bar widget that displays real-time battery status from your Marstek energy storage device.

Shows battery SOC percentage and charging state directly in the menu bar.

<!-- ![Screenshot](screenshot.png) -->

## Installation

1. Download `MarstekWidget.zip` from [Releases](../../releases/latest)
2. Unzip and drag `MarstekWidget.app` to `/Applications`
3. On first launch: right-click the app → **Open** (required for unsigned apps)

## Usage

1. Launch the app — a battery icon appears in the menu bar
2. Open **Settings** from the menu bar dropdown
3. Enter your Marstek device IP address
4. The widget polls the device and displays current battery percentage

## Build from source

Requires Swift 5.9+ and macOS 14+.

```bash
# Build and create .app bundle
make app

# Create distributable .zip
make zip
```

The resulting `MarstekWidget.app` will be in the project root.
