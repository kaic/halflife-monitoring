# HalfLife Monitoring

<p align="center">
  <img src="HalfLifeMonitoring.png" alt="HalfLife Monitoring" width="400">
</p>
Minimal Half-Life style overlay theme for [Rainmater](https://www.rainmeter.net/) to watch CPU, GPU, RAM, disk, and network usage right on the desktop.

<p align="center">
  <strong>Sistema de monitoramento de hardware para Windows com overlay Rainmeter</strong>
</p>

<p align="center">
  <a href="README.pt-BR.md">🇧🇷 Português</a> •
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a>
</p>

---

## ✨ Features

- **CPU**: Usage % + Temperature °C
- **GPU**: Usage % + Temperature °C *(NVIDIA/AMD/Intel)*
- **RAM**: Usage in GB
- **Disk**: Read/Write activity in MB/s
- **Network**: Download/Upload in KB/s

### What makes it special?

- 🎯 **Real GPU monitoring** - Uses LibreHardwareMonitorLib for accurate readings
- ⚡ **Lightweight** - Minimal resource usage (~10MB RAM)
- 🎨 **Customizable** - Edit colors, position, and metrics easily
- 🔄 **Auto-start** - Runs on Windows startup
- 🆓 **Open Source** - MIT License

---

## 📋 Requirements

- **Windows 10/11** (x64)
- **Rainmeter 4.5+** - [Download here](https://www.rainmeter.net/)
- **.NET 8.0 Runtime** - [Download here](https://dotnet.microsoft.com/download/dotnet/8.0)

---

## 🚀 Installation

### Quick Install (Recommended)

1. **Download** the latest release: [HalfLifeMonitoring-Release.zip](../../releases/latest)
2. **Extract** the ZIP file
3. **Run** `setup.bat` as Administrator
4. **Done!** The overlay will appear in the top-right corner

### Manual Install

<details>
<summary>Click to expand manual installation steps</summary>

#### 1. Install Rainmeter Skin

- Double-click `HalfLifeMonitoring.rmskin`
- Follow the Rainmeter installer prompts

#### 2. Install TempBridge

- Copy the `TempBridge` folder to `C:\Program Files\HalfLifeMonitoring\`
- Run `install.bat` to add to Windows Startup
- Start `TempBridge.exe`

#### 3. Load the Skin

- Open Rainmeter
- Find "HalfLifeMonitoring" in the skin list
- Click "Load"

</details>

---

## 🎮 Usage

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

**Disk always 0 KB/s?**

- Run `fix_disk_monitoring.bat` as Administrator
- Restart your computer

**Skin not loading?**

- Refresh Rainmeter (right-click → Refresh All)
- Check Rainmeter logs for errors

---

## 🛠 Building from Source

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
dotnet build -c Release

# Create release package
cd ../scripts
build-release.bat
```

Output will be in `dist/` folder.

---

## 📂 Project Structure

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

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [LibreHardwareMonitorLib](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor) - Hardware monitoring library
- [Rainmeter](https://www.rainmeter.net/) - Desktop customization platform

---

## 📧 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)

---

<p align="center">Made with ❤️ by <a href="https://github.com/yourusername">Kaic</a></p>
