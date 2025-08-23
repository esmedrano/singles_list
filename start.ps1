#!/usr/bin/env pwsh

# Configuration
$EmulatorDataDir = ".\emulator-data"
$ExportFile = "$EmulatorDataDir\firebase-export-metadata.json"
$FirebaseConfig = ".\firebase.json"
$SeedScript = ".\seed.js"
$ProjectId = "integridate"

# Ensure the emulator data directory exists
if (-not (Test-Path $EmulatorDataDir)) {
    New-Item -ItemType Directory -Path $EmulatorDataDir | Out-Null
}

# Check if Firebase CLI is installed
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Firebase CLI not found. Please install it using 'npm install -g firebase-tools'."
    exit 1
}

# Check if firebase.json exists and includes Authentication emulator
if (-not (Test-Path $FirebaseConfig)) {
    Write-Host "firebase.json not found in the project directory. Please ensure Firebase is initialized."
    exit 1
}
try {
    $firebaseJson = Get-Content $FirebaseConfig -Raw | ConvertFrom-Json
    if (-not $firebaseJson.emulators.auth) {
        Write-Host "Warning: Authentication emulator not configured in firebase.json. Auth users may not be exported."
    }
} catch {
    Write-Host "Error reading firebase.json: $($_.Exception.Message)"
    exit 1
}

# Check if Node.js is installed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js not found. Please install it to run the seeding script."
    exit 1
}

# Check if seeding script exists
if (-not (Test-Path $SeedScript)) {
    Write-Host "Seeding script ($SeedScript) not found. Please create it with the seeding logic."
    exit 1
}

# Set Firebase project ID
try {
    $currentProject = firebase use --json | ConvertFrom-Json
    if ($currentProject.status -eq "success" -and $currentProject.result.active -ne $ProjectId) {
        Write-Host "Setting Firebase project to $ProjectId..."
        firebase use $ProjectId
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to set project ID '$ProjectId'. Run 'firebase use --add $ProjectId' to configure it."
            exit 1
        }
    }
} catch {
    Write-Host "Error validating project ID: $($_.Exception.Message)"
    exit 1
}

# Check for lingering emulator processes on common ports
Write-Host "Checking for lingering emulator processes..."
$ports = @(4000, 8080, 9001, 9099, 9199, 4400, 4500, 9150)
foreach ($port in $ports) {
    $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($process) {
        Write-Host "Found process on port $port (PID: $process). Terminating..."
        Stop-Process -Id $process -Force -ErrorAction SilentlyContinue
    }
}

# Start Firebase emulators with import and export options
Write-Host "Starting Firebase emulators for project $ProjectId..."
$emulatorArgs = "emulators:start --import=`"$EmulatorDataDir`" --export-on-exit=`"$EmulatorDataDir`" --project $ProjectId --debug > emulator.log 2>&1"
if (-not (Test-Path $ExportFile)) {
    Write-Host "No previous emulator data found at $ExportFile."
}

$emulatorProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c firebase $emulatorArgs" -PassThru -NoNewWindow

# Wait for emulator to start with health check
Write-Host "Waiting for emulator UI to start..."
$emulatorReady = $false
$maxAttempts = 30
$attempt = 1
while (-not $emulatorReady -and $attempt -le $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:4000" -Method Get -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "Firebase emulator UI is accessible at http://127.0.0.1:4000. Assuming emulator is ready."
            $emulatorReady = $true
        }
    } catch {
        Write-Host "Attempt $attempt/${maxAttempts}: Emulator UI not ready yet at http://127.0.0.1:4000... Error: $($_.Exception.Message)"
        Start-Sleep -Seconds 3
        $attempt++
    }
}

if (-not $emulatorReady) {
    Write-Host "Firebase emulator failed to start within the timeout period. Check emulator.log for details."
    Stop-Process -Id $emulatorProcess.Id -Force -ErrorAction SilentlyContinue
    exit 1
}

# Run the seeding script only if no export data exists
if (-not (Test-Path $ExportFile)) {
    Write-Host "Running seeding script..."
    node $SeedScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Seeding failed. Stopping emulator..."
        Start-Sleep -Seconds 15 # Allow export before stopping
        Stop-Process -Id $emulatorProcess.Id -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "Existing emulator data found at $ExportFile. Skipping seeding to preserve data including auth users."
}

# Keep emulator running
Write-Host "All emulators are running. Press Ctrl+C to stop."
try {
    Wait-Process -Id $emulatorProcess.Id -ErrorAction Stop
} catch {
    Write-Host "Emulator process terminated: $($_.Exception.Message)"
} finally {
    Write-Host "Cleaning up emulator processes..."
    Write-Host "Waiting for emulator to export data to $EmulatorDataDir..."
    Start-Sleep -Seconds 15 # Give emulator ample time to export
    Stop-Process -Id $emulatorProcess.Id -Force -ErrorAction SilentlyContinue
}