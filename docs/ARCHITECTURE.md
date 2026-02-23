# Architecture

## Overview

MarstekWidget is a Swift Package Manager executable that runs as a macOS menu bar app. It polls a Marstek energy storage device over UDP/JSON-RPC and displays real-time status.

No Xcode project — the app is built with `swift build` and packaged into a `.app` bundle via Makefile.

## Component diagram

```
┌─────────────────────────────────────────────────┐
│  MarstekWidgetApp (@main)                       │
│  └─ MenuBarExtra (.window style)                │
│      ├─ menuBarLabel: battery icon + SOC %      │
│      └─ StatusMenuView: full status panel       │
├─────────────────────────────────────────────────┤
│  DeviceMonitor (@Observable)                    │
│  ├─ Owns polling Timer                          │
│  ├─ Holds CombinedStatus (aggregated state)     │
│  ├─ Persists settings via UserDefaults          │
│  └─ Delegates network calls to MarstekAPIClient │
├─────────────────────────────────────────────────┤
│  MarstekAPIClient (actor)                       │
│  └─ UDP via NWConnection → JSON-RPC 2.0        │
│     Port 30000, 5s timeout, 2 retries           │
└─────────────────────────────────────────────────┘
```

## File structure

```
Sources/MarstekWidget/
├── MarstekWidgetApp.swift      Entry point. MenuBarExtra scene.
├── Models/
│   ├── DeviceStatus.swift      Data models: ESStatus, BatStatus, EMStatus, ESMode, CombinedStatus
│   └── JSONRPCMessage.swift    JSON-RPC request/response types, AnyCodable helper
├── Services/
│   ├── DeviceMonitor.swift     Central state manager. Polling, settings, mode switching.
│   ├── MarstekAPIClient.swift  Network layer. UDP transport, retry logic.
│   └── SettingsWindowManager.swift  NSWindow management for Settings panel.
└── Views/
    ├── StatusMenuView.swift    Menu bar dropdown content.
    └── SettingsView.swift      Settings form (IP, polling interval, launch at login).
```

## Key components

### MarstekWidgetApp
Entry point using `@main`. Creates a `MenuBarExtra` with `.window` style — this gives a popover-like panel instead of a plain NSMenu. The label shows a dynamic SF Symbol battery icon and SOC percentage.

### DeviceMonitor
`@Observable` class, injected into views via SwiftUI environment. Responsibilities:
- Manages a repeating `Timer` for periodic polling
- Calls four API methods per poll cycle: `ES.GetStatus`, `Bat.GetStatus`, `EM.GetStatus`, `ES.GetMode`
- Aggregates results into `CombinedStatus`
- Tracks `ConnectionState` (disconnected / connecting / connected / error)
- Persists `deviceIP`, `pollingInterval`, `launchAtLogin` in `UserDefaults`
- Exposes `setMode()` for switching between Auto and Manual modes

### MarstekAPIClient
Swift `actor` for thread-safe network operations. Each request:
1. Opens a new `NWConnection` (UDP) to `host:30000`
2. Sends a JSON-RPC 2.0 request
3. Waits for a single UDP response
4. Decodes the `result` field into the expected type
5. Closes the connection

Retry policy: up to 2 retries with 500ms delay between attempts. Timeout: 5 seconds per attempt.

### SettingsWindowManager
Singleton that manages a standalone `NSWindow` for settings. When opened, the app temporarily switches from `.accessory` (no dock icon) to `.regular` activation policy so the window gets full focus. Reverts when the window closes.

### CombinedStatus
Value type that aggregates data from all four API responses. Provides computed properties that unify data from different sources (e.g., `soc` prefers `ESStatus.batSoc`, falls back to `BatStatus.soc`).

## API protocol

Communication uses JSON-RPC 2.0 over UDP port 30000.

### Methods

| Method | Returns | Description |
|---|---|---|
| `ES.GetStatus` | `ESStatus` | SOC, PV power, grid power, load power, energy counters |
| `Bat.GetStatus` | `BatStatus` | SOC, charge/discharge flags, temperature, capacity |
| `EM.GetStatus` | `EMStatus` | Energy meter: per-phase and total grid power |
| `ES.GetMode` | `ESMode` | Current operating mode (Auto/Manual) |
| `ES.SetMode` | `ESMode` | Change operating mode |

### Request example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "ES.GetStatus",
  "params": {"id": 0}
}
```

### Response example

```json
{
  "id": 1,
  "src": "venus_a",
  "result": {
    "bat_soc": 72,
    "pv_power": 1450,
    "ongrid_power": -320,
    "offgrid_power": 580,
    "total_pv_energy": 15420,
    "total_grid_input_energy": 3200,
    "total_grid_output_energy": 8750
  }
}
```

## Settings persistence

All settings stored in `UserDefaults` with these keys:

| Key | Type | Default | Description |
|---|---|---|---|
| `deviceIP` | String | `""` | Device IP address |
| `pollingInterval` | Double | `60` | Seconds between polls (clamped 10–600) |
| `launchAtLogin` | Bool | `false` | Launch at login preference (UI only, no launchd registration) |

## Build pipeline

The `Makefile` handles building and packaging:

1. `swift build -c release [--arch arm64|x86_64]` compiles the binary
2. Binary is copied into a `.app` bundle alongside `Info.plist`
3. `ditto` creates a `.zip` archive for distribution
4. `make release` builds both architectures

The app runs as `LSUIElement` (no dock icon) — configured in `Info.plist`.
