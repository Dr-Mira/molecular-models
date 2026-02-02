<#
.SYNOPSIS
    Validates that folders exist for molecules defined in a JSON file.
#>

# --- Configuration ---
# CHANGE THIS to the actual name of your json file
$JsonFileName = "molecules.json" 

# We get the directory where this script is running to avoid path confusion
$ScriptRoot = $PSScriptRoot 
$JsonFilePath = Join-Path $ScriptRoot $JsonFileName
$AssetsBaseDir = Join-Path $ScriptRoot "assets"

# --- Main Script ---

Clear-Host
Write-Host "Starting Folder Validation..." -ForegroundColor Cyan

# 1. Check if JSON file exists
if (-not (Test-Path $JsonFilePath)) {
    Write-Error "Could not find the JSON file at: $JsonFilePath"
    Write-Host "Please check the `$JsonFileName variable at the top of the script."
    exit
}

# 2. Load and Parse JSON
try {
    # -Raw reads the file as one single string, which is faster and safer for JSON
    $jsonObj = Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse JSON. Please check the file syntax."
    Write-Error $_.Exception.Message
    exit
}

# 3. Loop through the items
# We specifically target $jsonObj.value because your JSON wraps the array in a "value" property.
$countFound = 0
$countMissing = 0

foreach ($mol in $jsonObj.value) {
    
    # Construct the path: assets/pack_name/molecule_name
    # We use Join-Path to automatically handle backslashes correctly
    $packPath = Join-Path $AssetsBaseDir $mol.pack
    $fullPath = Join-Path $packPath $mol.name

    # 4. Validate the path
    if (Test-Path $fullPath) {
        Write-Host " [OK] Found: " -NoNewline -ForegroundColor Green
        Write-Host "$($mol.name)" -ForegroundColor Gray
        $countFound++
    }
    else {
        Write-Host "[MISSING] Could not find folder: " -NoNewline -ForegroundColor Red
        Write-Host "$fullPath" -ForegroundColor Yellow
        $countMissing++
    }
}

# --- Summary ---
Write-Host "`n-----------------------------"
Write-Host "Validation Complete."
Write-Host "Folders Found:   $countFound" -ForegroundColor Green
Write-Host "Folders Missing: $countMissing" -ForegroundColor Red