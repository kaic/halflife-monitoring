# HalfLife Monitoring Theme for Rainmeter

<p align="center">
  <img src="HalfLifeMonitoring.png" alt="HalfLife Monitoring" width="400"/>
</p>

Minimal hardware monitoring Half-Life style overlay theme for [Rainmeter](https://www.rainmeter.net/) to watch CPU, GPU, and more.

  <a href="#features">Features</a>
  <a href="#installation">Installation</a>
  <a href="#usage">Usage</a>
</p>

---

## Features

- **CPU**: Usage % + Temperature °C
- **GPU**: Usage % + Temperature °C *(NVIDIA/AMD/Intel)*
- **RAM**: Usage in GB
- **Disk**: Read/Write activity in MB/s
- **Network**: Download/Upload in MB/s

### Key Benefits

- **Real GPU monitoring** - Uses LibreHardwareMonitorLib for accurate readings
- **Lightweight** - Minimal resource usage (~10MB RAM)
- **Customizable** - Edit colors, position, and metrics easily
- **Auto-start** - Runs on Windows startup
- **Open Source** - MIT License

---

## Requirements

- **Windows 10/11** (x64)
- **Rainmeter 4.5+** - [Download](https://www.rainmeter.net/)
- **.NET 8.0 Runtime** - [Download](https://dotnet.microsoft.com/download/dotnet/8.0)

---

## Installation

### Quick Install (Recommended)

1. **Download** the latest `.rmskin` file: [Releases Page](https://github.com/kaic/halflife-monitoring/releases)
2. **Double-click** the file to install with Rainmeter
3. **Follow** the installer prompts (it will set up TempBridge automatically)
4. **Done!** The overlay will appear in the top-right corner

### Manual Install

<details>
<summary>Click to expand manual installation steps</summary>

#### 1. Install Rainmeter Skin

- Double-click `HalfLifeMonitoring.rmskin`
- Follow the Rainmeter installer prompts

#### 2. Install TempBridge (hidden background helper)

- Open **Command Prompt as Administrator**
- Run `TempBridge\install.bat`
- The script copies `TempBridge.exe` to `%ProgramData%\TempBridge`, registers it under `HKLM\Software\...\Run`, and launches it hidden on every logon
- During install we automatically run `Unblock-File` so SmartScreen should not prompt; if your AV flags it, allow it once
- Use `TempBridge\uninstall.bat` (Admin) if you want to remove the auto-start entry later

#### 3. Load the Skin

- Open Rainmeter
- Find "HalfLifeMonitoring" in the skin list
- Click "Load"

</details>

---

## Usage

### First Run

After installation, you should see:

- TempBridge running (console window or tray icon)
- Rainmeter overlay in the top-right corner
- All metrics updating in real-time

### Customization

Edit `HalfLifeMonitoring.ini` to customize:

```ini
[Variables]
; Change colors (R,G,B,Alpha)
textColor=0,255,255,190
barColor=0,255,255,160

; Change position
WindowX=(#SCREENAREAWIDTH# - #width# - 20)
WindowY=40
```

### Troubleshooting

**GPU shows 0%?**

- Ensure TempBridge is running
- Check that `@Resources/hwstats.txt` exists and is being updated
- Try restarting TempBridge

**Disk always 0 MB/s?**

- Open Command Prompt as Administrator
- Run: `lodctr /r`
- Restart your computer

**Skin not loading?**

- Refresh Rainmeter (right-click → Refresh All)
- Check Rainmeter logs for errors

---

## Building from Source

### Prerequisites

- .NET 8.0 SDK
- Visual Studio 2022 or VS Code (optional)

### Build Steps

```bash
# Clone the repository
git clone https://github.com/yourusername/halflife-monitoring.git
cd halflife-monitoring

# Build TempBridge
cd TempBridge
dotnet restore
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o ../dist/TempBridge
```

Output will be in `dist/` folder.

---

## Project Structure

```
halflife-monitoring/
├── TempBridge/              # C# background service
│   ├── Program.cs           # Main sensor reading logic
│   ├── TempBridge.csproj    # Project file
│   └── install.bat          # Startup installer
├── HalfLifeMonitoring.ini   # Rainmeter skin
├── @Resources/              # Skin resources
│   └── hwstats.txt          # Sensor data (generated)
├── scripts/                 # Build automation
│   └── build-release.bat
├── installer/               # Distribution
│   └── setup.bat
└── README.md
```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [LibreHardwareMonitorLib](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor) - Hardware monitoring library
- [Rainmeter](https://www.rainmeter.net/) - Desktop customization platform

---

## Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)

---

<p align="center">Made by <a href="http://kaic.me/">Kaic</a></p>
