# install_flutter.ps1
# Chạy với PowerShell (không cần Admin)
# Usage: .\install_flutter.ps1

$flutterVersion = "3.22.2"
$flutterDir = "C:\flutter"
$zipPath = "$env:TEMP\flutter_windows.zip"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " In-Sight — Flutter Setup Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
if (Test-Path "$flutterDir\bin\flutter.bat") {
    Write-Host "[OK] Flutter đã được cài tại $flutterDir" -ForegroundColor Green
    & "$flutterDir\bin\flutter.bat" --version
} else {
    Write-Host "[1/3] Downloading Flutter $flutterVersion..." -ForegroundColor Yellow
    $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${flutterVersion}-stable.zip"

    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Write-Host "[2/3] Extracting to C:\..." -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath "C:\" -Force
        Remove-Item $zipPath -ErrorAction SilentlyContinue
        Write-Host "[OK] Extracted!" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Download thất bại: $_" -ForegroundColor Red
        Write-Host "Vui lòng tải thủ công từ: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
        exit 1
    }
}

# Add to PATH
Write-Host "[3/3] Adding to PATH..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$flutterDir\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterDir\bin", "User")
    Write-Host "[OK] Added $flutterDir\bin to PATH" -ForegroundColor Green
} else {
    Write-Host "[OK] PATH đã có Flutter" -ForegroundColor Green
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Bước tiếp theo:" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "1. Đóng và mở lại PowerShell/Terminal" -ForegroundColor White
Write-Host "2. Chạy: flutter doctor" -ForegroundColor White
Write-Host "3. Chạy: cd 'C:\Users\duth\OneDrive - MB Life\Documents\Claude\Projects\in_sight'" -ForegroundColor White
Write-Host "4. Chạy: flutter pub get" -ForegroundColor White
Write-Host "5. Chạy: flutter run -d chrome" -ForegroundColor White
Write-Host ""
Write-Host "Xem chi tiết tại: SETUP.md" -ForegroundColor Gray
