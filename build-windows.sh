#!/bin/bash

echo "========================================"
echo "TempBridge - Build para Windows (Linux)"
echo "========================================"
echo ""

# Verifica se .NET SDK está instalado
if ! command -v dotnet &> /dev/null; then
    echo "[!] .NET SDK não encontrado. Instalando..."
    echo ""
    
    # Detecta a distribuição
    if [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        echo "Detectado: Ubuntu/Debian"
        wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
        chmod +x dotnet-install.sh
        ./dotnet-install.sh --channel 8.0
        export PATH="$HOME/.dotnet:$PATH"
        rm dotnet-install.sh
    elif [ -f /etc/fedora-release ]; then
        # Fedora
        echo "Detectado: Fedora"
        sudo dnf install dotnet-sdk-8.0 -y
    elif [ -f /etc/arch-release ]; then
        # Arch
        echo "Detectado: Arch Linux"
        sudo pacman -S dotnet-sdk-8.0 --noconfirm
    else
        echo "[ERRO] Distribuição não suportada automaticamente."
        echo "Instale manualmente: https://dotnet.microsoft.com/download"
        exit 1
    fi
    
    echo ""
fi

# Verifica novamente
if ! command -v dotnet &> /dev/null; then
    echo "[ERRO] Falha ao instalar .NET SDK"
    exit 1
fi

echo "[OK] .NET SDK instalado"
dotnet --version
echo ""

# Navega para a pasta do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/TempBridge"

if [ ! -f "$PROJECT_DIR/TempBridge.csproj" ]; then
    echo "[ERRO] TempBridge.csproj não encontrado em: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "[1/3] Restaurando dependências..."
dotnet restore
if [ $? -ne 0 ]; then
    echo "[ERRO] Falha ao restaurar dependências"
    exit 1
fi
echo ""

echo "[2/3] Compilando para Windows (win-x64)..."
echo "       - Self-contained: true (NÃO requer .NET Runtime no Windows)"
echo "       - Single file: true (executável único ~70MB)"
echo ""

dotnet publish -c Release -r win-x64 \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:EnableCompressionInSingleFile=true \
    -o "$SCRIPT_DIR/dist/TempBridge"

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERRO] Falha na compilação"
    exit 1
fi

echo ""
echo "[3/3] Copiando arquivos adicionais..."
cp "$PROJECT_DIR/install.bat" "$SCRIPT_DIR/dist/TempBridge/" 2>/dev/null

echo ""
echo "========================================"
echo "✓ Build Concluído!"
echo "========================================"
echo ""
echo "Executável gerado em:"
echo "  📁 $SCRIPT_DIR/dist/TempBridge/TempBridge.exe"
echo ""
echo "Próximos passos:"
echo "  1. Copie a pasta 'dist/TempBridge' para o Windows"
echo "  2. No Windows, certifique-se de ter .NET 8 Runtime:"
echo "     https://dotnet.microsoft.com/download/dotnet/8.0/runtime"
echo "  3. Execute: TempBridge.exe"
echo ""
echo "Tamanho do arquivo:"
ls -lh "$SCRIPT_DIR/dist/TempBridge/TempBridge.exe" | awk '{print "  " $9 " -> " $5}'
echo ""
