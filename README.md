# Half-Life Monitoring (Rainmeter)

Minimal Half-Life style overlay to watch CPU, GPU, RAM, disk, and network usage right on the desktop.

Português: [README.pt-BR.md](README.pt-BR.md)

![Skin preview](HalfLifeMonitoring.png)

## Features
- CPU and GPU percentages with horizontal bars.
- RAM in GB (used/total) plus a percentage bar.
- Disk: aggregated read and write (KB/s).
- Network: download and upload (KB/s) in a single line.
- Always on the top-right corner, translucent background, with click-through enabled.

## Requirements
- Windows 10/11 (UsageMonitor relies on Windows performance counters).
- Rainmeter 4.5+.

## Installation
1) **Packaged (automatic)**: open `HalfLifeMonitoring_1.0.rmskin` and follow the Rainmeter installer. This deploys the skin and assets for you.  
2) **Manual (alternative)**: copy `HalfLifeMonitoring.ini` to `Documents\Rainmeter\Skins\HalfLifeMonitoring\` and load the skin in Rainmeter. Use this if you prefer to inspect/edit the source directly.

## How to use
- On load, the overlay is placed top-right (`WindowX/Y`) with `AlwaysOnTop` and `ClickThrough` enabled so it does not block clicks.
- Refresh runs every 300 ms (`Update=300`).
- If GPU stays at 0%, adjust `Instance` in `measureGPUUsage` to the correct GPU counter instance (see Performance Monitor/UsageMonitor).

## Quick customization
- Colors and transparency: `textColor`, `barColor`, `bgColor`.
- Font/size: `fontName`, `textSize`.
- Dimensions/padding: `width`, `height`, plus `WindowX`/`WindowY`.
- Behavior: toggle `ClickThrough` or `Draggable` by changing `OnRefreshAction`.

## File layout
- `HalfLifeMonitoring.ini` — skin source code (what ships inside the `.rmskin`).
- `HalfLifeMonitoring_1.0.rmskin` — installable package (auto-setup).
- `HalfLifeMonitoring.png` — screenshot.

## Publish a GitHub Release (for downloads)
1) Push this repo to GitHub.  
2) In the repo page, go to **Releases** → **Draft a new release**.  
3) Tag: `v1.0.0` (or current version), title: “Half-Life Monitoring 1.0.0”.  
4) Description: short changelog/notes.  
5) Upload `HalfLifeMonitoring_1.0.rmskin` as a binary asset.  
6) Publish the release so users can download the package directly.

## Contributing
Issues and PRs are welcome. Feel free to tweak counters, colors, layout, or add variants.

## License
MIT — see `LICENSE`.
