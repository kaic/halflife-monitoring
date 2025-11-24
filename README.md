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
1) **Packaged**: open `HalfLifeMonitoring_1.0.rmskin` and follow the Rainmeter installer.  
2) **Manual**: copy `HalfLifeMonitoring.ini` to `Documents\Rainmeter\Skins\HalfLifeMonitoring\` and load the skin in Rainmeter.

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
- `HalfLifeMonitoring.ini` — skin source code.
- `HalfLifeMonitoring_1.0.rmskin` — installable package.
- `HalfLifeMonitoring.png` — screenshot.

## Contributing
Issues and PRs are welcome. Feel free to tweak counters, colors, layout, or add variants.

## License
MIT — see `LICENSE`.
