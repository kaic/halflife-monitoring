#!/bin/bash

echo "========================================"
echo "TempBridge - Windows Build (Linux host)"
echo "========================================"
echo ""

# Ensure .NET SDK is installed
if ! command -v dotnet &> /dev/null; then
    echo "[!] .NET SDK not found. Installing..."
    echo ""
    
    # Detect distro
    if [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        echo "Detected: Ubuntu/Debian"
        wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
        chmod +x dotnet-install.sh
        ./dotnet-install.sh --channel 8.0
        export PATH="$HOME/.dotnet:$PATH"
        rm dotnet-install.sh
    elif [ -f /etc/fedora-release ]; then
        # Fedora
        echo "Detected: Fedora"
        sudo dnf install dotnet-sdk-8.0 -y
    elif [ -f /etc/arch-release ]; then
        # Arch
        echo "Detected: Arch Linux"
        sudo pacman -S dotnet-sdk-8.0 --noconfirm
    else
        echo "[ERROR] Unsupported distro for auto-install."
        echo "Install manually: https://dotnet.microsoft.com/download"
        exit 1
    fi
    
    echo ""
fi

# Double-check
if ! command -v dotnet &> /dev/null; then
    echo "[ERROR] Failed to install .NET SDK"
    exit 1
fi

echo "[OK] .NET SDK available"
dotnet --version
echo ""

# Go to project folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/TempBridge"

if [ ! -f "$PROJECT_DIR/TempBridge.csproj" ]; then
    echo "[ERROR] TempBridge.csproj not found at: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "[1/3] Restoring dependencies..."
dotnet restore
if [ $? -ne 0 ]; then
    echo "[ERROR] Restore failed"
    exit 1
fi
echo ""

echo "[2/3] Publishing for Windows (win-x64)..."
echo "       - Self-contained: true (no .NET Runtime required on Windows)"
echo "       - Single file: true (single executable ~70MB)"
echo ""

dotnet publish -c Release -r win-x64 \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:EnableCompressionInSingleFile=true \
    -o "$SCRIPT_DIR/dist/TempBridge"

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Publish failed"
    exit 1
fi

echo ""
echo "[3/3] Copying auxiliary files..."
cp "$PROJECT_DIR/install.bat" "$SCRIPT_DIR/dist/TempBridge/" 2>/dev/null

echo ""
echo "========================================"
echo "✓ Build Completed!"
echo "========================================"
echo ""
echo "Executable generated at:"
echo "  📁 $SCRIPT_DIR/dist/TempBridge/TempBridge.exe"
echo ""
echo "Next steps:"
echo "  1. Copy the 'dist/TempBridge' folder to Windows"
echo "  2. On Windows ensure .NET 8 Runtime is installed:"
echo "     https://dotnet.microsoft.com/download/dotnet/8.0/runtime"
echo "  3. Run: TempBridge.exe"
echo ""
echo "File size:"
ls -lh "$SCRIPT_DIR/dist/TempBridge/TempBridge.exe" | awk '{print "  " $9 " -> " $5}'
echo ""
