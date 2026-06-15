param(
    [string]$OutDir = ".\dist\coka_billing_windows"
)

Write-Host "Packaging COKA Billing Windows distribution..." -ForegroundColor Cyan

# Build if not already built
if (-not (Test-Path "build\windows\x64\runner\Release\coka_billing.exe")) {
    Write-Host "Building Windows release..." -ForegroundColor Yellow
    $env:FIREBASE_CPP_SDK_DIR = "C:\firebase_cpp_sdk\firebase_cpp_sdk_windows"
    $result = flutter build windows --release 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build FAILED. Output:" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
}

$src = "build\windows\x64\runner\Release"
if (-not (Test-Path "$src\coka_billing.exe")) {
    Write-Host "ERROR: Build not found at $src" -ForegroundColor Red
    exit 1
}

# Verify data directory exists
if (-not (Test-Path "$src\data\app.so")) {
    Write-Host "ERROR: Missing data\app.so - build incomplete!" -ForegroundColor Red
    exit 1
}

# Create dist folder
Remove-Item -Recurse -Path $OutDir -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# Copy ALL files recursively from Release folder
Write-Host "Copying all build output..." -ForegroundColor Cyan
Copy-Item -Path "$src\*" -Destination $OutDir -Recurse -Force

# Copy setup script
Copy-Item -Path "setup_and_run.bat" -Destination "$OutDir\setup_and_run.bat" -Force

# Size report
$size = (Get-ChildItem -Recurse $OutDir | Measure-Object -Property Length -Sum).Sum
$fileCount = (Get-ChildItem -Recurse $OutDir).Count
Write-Host "Distribution packaged: $OutDir" -ForegroundColor Green
Write-Host "Total size: $([math]::Round($size / 1MB, 1)) MB" -ForegroundColor Green
Write-Host "Files: $fileCount" -ForegroundColor Green

# Clean up build intermediates to save disk space (but NOT the data dir!)
Write-Host "Cleaning build intermediates..." -ForegroundColor Yellow
$beforeClean = (Get-PSDrive C).Free
# Remove CMake intermediate files but keep the Release output
Remove-Item -Recurse -Force "build\windows\flutter" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "build\windows\x64\CMakeFiles" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "build\windows\x64\flutter" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "build\windows\x64\plugins" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "build\windows\x64\runner" -ErrorAction SilentlyContinue
# Keep only the Release output
$afterClean = (Get-PSDrive C).Free
$freed = [math]::Round(($afterClean - $beforeClean) / 1GB, 1)
Write-Host "Freed $freed GB" -ForegroundColor Green
Write-Host "Free space: $([math]::Round($afterClean/1GB, 1)) GB" -ForegroundColor Green
