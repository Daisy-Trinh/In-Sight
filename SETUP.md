# In-Sight — Hướng dẫn setup môi trường

## Bước 1: Cài Flutter SDK (Windows)

Mở PowerShell với quyền Admin, chạy lệnh sau:

```powershell
# Tải Flutter SDK
$flutterVersion = "3.22.0"
$url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${flutterVersion}-stable.zip"
$dest = "C:\flutter"

Write-Host "Downloading Flutter $flutterVersion..."
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\flutter.zip"

Write-Host "Extracting..."
Expand-Archive -Path "$env:TEMP\flutter.zip" -DestinationPath "C:\" -Force

# Thêm vào PATH (user-level)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*C:\flutter\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\flutter\bin", "User")
    Write-Host "Added C:\flutter\bin to PATH"
}

Write-Host "Done! Restart PowerShell then run: flutter doctor"
```

## Bước 2: Cài Android Studio

1. Tải từ: https://developer.android.com/studio
2. Cài xong → mở Android Studio → Install SDK Tools:
   - Android SDK
   - Android SDK Command-line Tools
   - Android Emulator

## Bước 3: Verify

```bash
flutter doctor
```

Kết quả mong muốn:
```
[✓] Flutter (Channel stable, 3.22.0)
[✓] Android toolchain
[✓] VS Code
[!] Xcode (chỉ cần nếu build iOS, cần máy Mac)
```

## Bước 4: Cài dependencies

```bash
cd "C:\Users\duth\OneDrive - MB Life\Documents\Claude\Projects\in_sight"
flutter pub get
```

## Bước 5: Chạy app

```bash
# Android (cần emulator hoặc cắm điện thoại)
flutter run

# Web (không cần emulator)
flutter run -d chrome

# List thiết bị
flutter devices
```

## Bước 6: Setup Git & GitHub

```bash
git config --global user.email "daisy.trinh0592@gmail.com"
git config --global user.name "Daisy Trinh"

cd "C:\Users\duth\OneDrive - MB Life\Documents\Claude\Projects\in_sight"
git init
git add .
git commit -m "feat: init In-Sight Flutter project"

# Tạo repo trên GitHub trước tại github.com, rồi:
git remote add origin https://github.com/daisy-trinh/in-sight.git
git push -u origin main
```

## Cấu trúc project

```
lib/
├── main.dart                    # Entry point
├── core/
│   ├── theme/
│   │   ├── design_tokens.dart   # Màu sắc, typography, spacing
│   │   └── app_theme.dart       # Light + Dark theme
│   ├── store/
│   │   └── app_store.dart       # LocalStorage, quota, sessions
│   ├── api/
│   │   └── api_client.dart      # API_Contract.md implementation
│   └── router/
│       └── app_router.dart      # GoRouter navigation
├── features/
│   ├── home/
│   │   └── home_page.dart       # Splash + Persona select
│   ├── chat/
│   │   └── chat_page.dart       # Chat với AI streaming
│   ├── journey/
│   │   └── journey_page.dart    # Lịch sử các session
│   └── settings/
│       └── settings_page.dart   # Dark mode, Cascade Wipe
├── features/personas/
│   └── persona_engine.dart      # AI response logic (offline)
└── shared/
    └── models/
        └── persona.dart         # Data models
```
