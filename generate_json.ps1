<#
.SYNOPSIS
    Validates folders exist AND updates the JSON file with found JPG images.
#>

# --- Configuration ---
$JsonFileName = "molecules.json" 

$ScriptRoot = $PSScriptRoot 
$JsonFilePath = Join-Path $ScriptRoot $JsonFileName
$AssetsBaseDir = Join-Path $ScriptRoot "assets"

# --- Main Script ---

Clear-Host
Write-Host "Starting Folder Validation and Image Sync..." -ForegroundColor Cyan

# 1. Check if JSON file exists
if (-not (Test-Path $JsonFilePath)) {
    Write-Error "Could not find the JSON file at: $JsonFilePath"
    exit 1
}

# 2. Load and Parse JSON
try {
    $jsonContent = Get-Content -Path $JsonFilePath -Raw
    $jsonObj = $jsonContent | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse JSON. Please check the file syntax."
    Write-Error $_.Exception.Message
    exit 1
}

$countFound = 0
$countMissing = 0
$filesUpdated = 0

# 3. Loop through the items
foreach ($mol in $jsonObj.value) {
    
    $packPath = Join-Path $AssetsBaseDir $mol.pack
    $fullPath = Join-Path $packPath $mol.name

    # 4. Validate the path
    if (Test-Path $fullPath) {
        Write-Host " [OK] Found: " -NoNewline -ForegroundColor Green
        Write-Host "$($mol.name)" -ForegroundColor Gray
        $countFound++

        # --- NEW LOGIC: SCAN AND UPDATE IMAGES ---
        
        # Find all jpg/jpeg files in this folder
        $imageFiles = Get-ChildItem -Path $fullPath -Include "*.jpg", "*.jpeg" -File

        # Create an empty array (ArrayList) to hold the new paths
        $newImageList = [System.Collections.Generic.List[string]]::new()

        foreach ($img in $imageFiles) {
            # Convert absolute path to relative path (e.g., assets/pack/name/image.jpg)
            # We remove the ScriptRoot length plus one for the slash
            $relativePath = $img.FullName.Substring($ScriptRoot.Length + 1)
            
            # Ensure we use forward slashes for JSON (web standard)
            $relativePath = $relativePath -replace '\\', '/'
            
            $newImageList.Add($relativePath)
        }

        # Update the JSON object in memory
        # We sort them to keep the JSON tidy
        $mol.images = $newImageList | Sort-Object
        $filesUpdated += $newImageList.Count
    }
    else {
        Write-Host "[MISSING] Could not find folder: " -NoNewline -ForegroundColor Red
        Write-Host "$fullPath" -ForegroundColor Yellow
        $countMissing++
    }
}

# 5. Save the updated JSON back to disk
# Only save if we actually found folders to avoid wiping data on a bad run
if ($countFound -gt 0) {
    try {
        # Depth 10 ensures nested arrays don't get cut off
        $newJsonContent = $jsonObj | ConvertTo-Json -Depth 10
        Set-Content -Path $JsonFilePath -Value $newJsonContent
        Write-Host "`nJSON file updated successfully." -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to save JSON file."
        exit 1
    }
}

# --- Summary ---
Write-Host "`n-----------------------------"
Write-Host "Validation Complete."
Write-Host "Folders Found:   $countFound" -ForegroundColor Green
Write-Host "Folders Missing: $countMissing" -ForegroundColor Red
Write-Host "Images Linked:   $filesUpdated" -ForegroundColor Magenta

# --- Explicit Exit Codes ---
if ($countMissing -gt 0) {
    # Exit with error code 1 so CI/CD pipelines know something failed
    Write-Error "Process failed because $countMissing folders are missing."
    exit 1
} else {
    # Exit with success code 0
    exit 0
}