# Hisabati ERP - Windows Auto Installer
# ------------------------------------
# This script will trust the application certificate and install the app.

$msixFile = "build\windows\x64\runner\Release\hisabati_app.msix"
$currentDir = Get-Location
$fullPath = Join-Path $currentDir $msixFile

# 1. Check for Admin Rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "⚠️  ERROR: ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Red
    Write-Host "Please Right-Click this script and choose 'Run with PowerShell'." -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
    Pause
    Exit
}

Write-Host "🚀 Starting Hisabati ERP Installation Core..." -ForegroundColor Cyan

# 2. Extract and Trust Certificate
Write-Host "📦 Extracting digital signature from $msixFile" -ForegroundColor White
if (-not (Test-Path $fullPath)) {
    Write-Host "❌ Error: MSIX file not found at $fullPath" -ForegroundColor Red
    Pause
    Exit
}

$signature = Get-AuthenticodeSignature -FilePath $fullPath

if ($signature.SignerCertificate -eq $null) {
    Write-Host "❌ Error: Could not find digital signature in $msixFile" -ForegroundColor Red
    Pause
    Exit
}

Write-Host "🔐 Adding certificate to Trusted Root..." -ForegroundColor White
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$store.Open("ReadWrite")
$store.Add($signature.SignerCertificate)
$store.Close()

# 3. Install MSIX
Write-Host "📥 Installing Hisabati ERP..." -ForegroundColor White
try {
    Add-AppxPackage -Path $fullPath -ErrorAction Stop
    Write-Host "✅ Installation Successful!" -ForegroundColor Green
    Write-Host "You can now find 'Hisabati ERP' in your Start Menu." -ForegroundColor White
} catch {
    Write-Host "❌ Installation failed: $_" -ForegroundColor Red
}

Write-Host "----------------------------------------------------------"
Pause
