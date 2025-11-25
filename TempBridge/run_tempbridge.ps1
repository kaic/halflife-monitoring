param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exePath = Join-Path $scriptDir 'TempBridge.exe'
$logPath = Join-Path $scriptDir 'run_tempbridge.log'

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $logPath -Value "[$timestamp] $msg"
}

try {
    if (-not (Test-Path -LiteralPath $exePath)) {
        Write-Log "ERROR: TempBridge.exe not found at $exePath"
        exit 1
    }

    $docs = $env:TEMPBRIDGE_DOCUMENTS
    if ([string]::IsNullOrWhiteSpace($docs)) {
        $docs = [Environment]::GetFolderPath('MyDocuments')
    }

    Write-Log "Start user=$env:USERNAME docs=$docs exe=$exePath"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.WorkingDirectory = $scriptDir
    $psi.UseShellExecute = $false
    $psi.WindowStyle = 'Hidden'
    $psi.CreateNoWindow = $true
    $psi.Environment['TEMPBRIDGE_DOCUMENTS'] = $docs

    if (-not [System.Diagnostics.Process]::Start($psi)) {
        Write-Log "ERROR: Failed to start TempBridge process."
        exit 1
    }

    Write-Log "TempBridge launched."
    exit 0
}
catch {
    Write-Log ("ERROR: " + $_.Exception.Message)
    exit 1
}
