# Configuration
$EmulatorDataDir = ".\emulator-data"
$ExportFile = "$EmulatorDataDir\emulator-export.json"
$FirebaseConfig = ".\firebase.json"

# Ensure the emulator data directory exists
if (-not (Test-Path $EmulatorDataDir)) {
    New-Item -ItemType Directory -Path $EmulatorDataDir | Out-Null
}

# Check if Firebase CLI is installed
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Firebase CLI not found. Please install it using 'npm install -g firebase-tools'."
    exit 1
}

# Check if firebase.json exists
if (-not (Test-Path $FirebaseConfig)) {
    Write-Host "firebase.json not found in the project directory. Please ensure Firebase is initialized."
    exit 1
}

# Start Firebase emulators with import and export options
Write-Host "Starting Firebase emulators..."
if (Test-Path $EmulatorDataDir) {
    Write-Host "Importing data from $EmulatorDataDir..."
    firebase emulators:start --import="$EmulatorDataDir" --export-on-exit="$EmulatorDataDir"
} else {
    Write-Host "No previous emulator data found. Starting fresh..."
    firebase emulators:start --export-on-exit="$EmulatorDataDir"
}

# Exit with the last command's exit code
exit $LASTEXITCODE