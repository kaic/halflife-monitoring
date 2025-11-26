# HalfLife Monitoring Theme for Rainmeter

<p align="center">
  <img src="desktop.png" alt="HalfLife Monitoring" width="420"/>
</p>
<p align="center">
  <img src="overlay.png" alt="Overlay Exemplo 1" width="360"/>
  <img src="overlay_2.png" alt="Overlay Exemplo 2" width="360"/>
</p>

Minimal hardware monitoring Half-Life style overlay theme for [Rainmeter](https://www.rainmeter.net/) to watch CPU, GPU, and more.

<a href="#features">Features</a>
<a href="#installation">Installation</a>
<a href="#usage">Usage</a>

---

## Features

- **CPU**: Usage % + Temperature °C
- **GPU**: Usage % + Temperature °C *(NVIDIA/AMD/Intel)*
- *(FPS temporariamente desativado enquanto buscamos uma fonte confiável)*

*Sobre o TempBridge:* O TempBridge é um helper .NET minúsculo (consome ~50 MB de RAM) que consulta os sensores do LibreHardwareMonitor e escreve `hwstats.txt`. O Rainmeter não enxerga temperatura/uso de GPU nativamente, então o TempBridge preenche essa lacuna e mantém a skin atualizada em segundo plano como um serviço oculto.
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

1. **Baixe** o `.rmskin` e os arquivos `TempBridge.exe` + `install.bat` da [página de releases](https://github.com/kaic/halflife-monitoring/releases) (deixe o `.exe` e o `.bat` na mesma pasta).
2. **Execute** o `.rmskin` para instalar a skin no Rainmeter.
3. **Abra** um Prompt de Comando como Administrador, navegue até a pasta do TempBridge e rode `install.bat` (ele instala o helper como serviço escondido do Windows).
4. **Pronto!** O overlay aparece no canto superior direito e o TempBridge inicializa automaticamente a cada boot.

### Manual Install

<details>
<summary>Click to expand manual installation steps</summary>

#### 1. Install Rainmeter Skin

- Double-click `HalfLifeMonitoring.rmskin`
- Follow the Rainmeter installer prompts

#### 2. Instalar o TempBridge (serviço oculto)

- Copie `TempBridge.exe` e `install.bat` (Assets do release) para a mesma pasta
- Abra um **Prompt de Comando como Administrador**
- Execute `install.bat`
- O script copia o helper para `%ProgramData%\TempBridge`, registra um serviço (LocalSystem, auto start) e o inicia oculto — isso garante que o Rainmeter tenha os sensores da GPU disponíveis sempre
- Durante a instalação rodamos `Unblock-File` para remover o SmartScreen; se o antivirus sinalizar, permita/ignore uma vez
- Se quiser remover depois, execute `TempBridge\uninstall.bat` (Administrador)

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

**Antivírus bloqueando o TempBridge?**

- Seu antivírus pode detectar o TempBridge como falso positivo devido ao acesso de baixo nível ao hardware
- O instalador detecta e configura automaticamente exclusões para mais de 10 produtos antivírus
- Se a detecção automática falhar, consulte o **[Guia de Correção de Antivírus](ANTIVIRUS_FIX.md)** para instruções manuais
- Antivírus suportados: Windows Defender, Bitdefender, Avast, AVG, Norton, McAfee, Kaspersky, ESET, Avira, Trend Micro, Malwarebytes, Sophos

---

## Building from Source

### Prerequisites

- .NET 8.0 SDK
- Visual Studio 2022 or VS Code (optional)

### Build Steps

```bash
# Clone the repository
git clone https://github.com/kaic/halflife-monitoring.git
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

<p align="center">Feito por <a href="http://kaic.me/">Kaic</a></p>
