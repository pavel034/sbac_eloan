# SBAC E-Loan - Firebase Setup Script
# Run this once after creating your Firebase project at console.firebase.google.com
#
# Usage:
#   .\setup_firebase.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SBAC E-Loan - Firebase Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH to include newly installed tools
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH","User")

# Step 1: Firebase login
Write-Host "Step 1: Logging into Firebase..." -ForegroundColor Yellow
Write-Host "(A browser window will open - sign in with your Google account)" -ForegroundColor Gray
firebase login
if ($LASTEXITCODE -ne 0) {
    Write-Host "Login failed. Please try again." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Configuring Firebase for this project..." -ForegroundColor Yellow
Write-Host "(Select your Firebase project when prompted)" -ForegroundColor Gray
Write-Host "(Enable Android, iOS, and Web platforms)" -ForegroundColor Gray
Write-Host ""

# Step 2: FlutterFire configure (auto-generates lib/firebase_options.dart)
dart pub global run flutterfire_cli:flutterfire configure `
    --project=your-firebase-project-id `
    --platforms=android,ios,web `
    --android-package-name=com.sbac.eloan `
    --ios-bundle-id=com.sbac.eloan `
    --out=lib/firebase_options.dart

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Note: If the above failed, run this instead:" -ForegroundColor Yellow
    Write-Host "  dart pub global run flutterfire_cli:flutterfire configure" -ForegroundColor White
    Write-Host "(It will ask you to select a project interactively)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 3: Enabling Firestore and Phone Auth..." -ForegroundColor Yellow
Write-Host "Please do these manually in the Firebase Console:" -ForegroundColor Gray
Write-Host "  1. Firestore Database -> Create database -> Test mode -> asia-south1 region" -ForegroundColor White
Write-Host "  2. Authentication -> Sign-in method -> Phone -> Enable" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup complete! Run: flutter run" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
