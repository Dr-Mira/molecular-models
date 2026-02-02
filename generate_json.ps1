<#
.SYNOPSIS
    Updates the images array in molecules.json based on files in the assets folder.
.DESCRIPTION
    This script reads the existing molecules.json, scans the assets folder for JPG/JPEG files,
    and updates only the images array for each molecule entry.
#>

# --- Configuration ---
$ScriptRoot = $PSScriptRoot
$AssetsBaseDir = Join-Path $ScriptRoot "assets"
$JsonFilePath = Join-Path $ScriptRoot "molecules.json"

# --- Main Script ---
Clear-Host
Write-Host "Starting Image Path Update..." -ForegroundColor Cyan

# 1. Check if JSON file exists
if (-not (Test-Path $JsonFilePath)) {
    Write-Error "Could not find molecules.json at: $JsonFilePath"
    exit 1
}

# 2. Check if assets directory exists
if (-not (Test-Path $AssetsBaseDir)) {
    Write-Error "Assets directory not found at: $AssetsBaseDir"
    exit 1
}

# 3. Load and Parse JSON
Write-Host "`nReading JSON file..." -ForegroundColor Yellow
try {
    $rawJson = Get-Content -Path $JsonFilePath -Raw
    Write-Host "File size: $($rawJson.Length) characters" -ForegroundColor Gray
    Write-Host "First 200 characters:" -ForegroundColor Gray
    Write-Host $rawJson.Substring(0, [Math]::Min(200, $rawJson.Length)) -ForegroundColor DarkGray
    
    $jsonContent = $rawJson | ConvertFrom-Json
    
    if ($null -eq $jsonContent) {
        Write-Error "JSON parsed to null - file may be empty or invalid"
        exit 1
    }
    
    Write-Host "`nJSON parsed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to parse JSON. Please check the file syntax."
    Write-Error $_.Exception.Message
    exit 1
}

# Debug: Check JSON structure
Write-Host "`nDEBUG: Examining JSON structure..." -ForegroundColor Yellow
Write-Host "Type: $($jsonContent.GetType().Name)" -ForegroundColor Gray
$properties = $jsonContent.PSObject.Properties | Select-Object -ExpandProperty Name
Write-Host "Properties: $($properties -join ', ')" -ForegroundColor Gray

# Check if it's an array or object with 'value' property
if ($jsonContent -is [Array]) {
    Write-Host "`nJSON is an array with $($jsonContent.Count) items" -ForegroundColor Cyan
    $molecules = $jsonContent
}
elseif ($properties -contains 'value') {
    Write-Host "`nJSON has 'value' property" -ForegroundColor Cyan
    $molecules = $jsonContent.value
    if ($molecules -is [Array]) {
        Write-Host "Value is an array with $($molecules.Count) items" -ForegroundColor Cyan
    }
    else {
        Write-Host "Value type: $($molecules.GetType().Name)" -ForegroundColor Gray
    }
}
else {
    Write-Error "Cannot find molecules in JSON. Unexpected structure."
    Write-Host "Available properties: $($properties -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "`nTotal molecules to process: $($molecules.Count)" -ForegroundColor Cyan

if ($molecules.Count -eq 0) {
    Write-Warning "No molecules found in JSON!"
    exit 0
}

# 4. Process each molecule in the JSON
$updatedCount = 0
$missingCount = 0
$unchangedCount = 0

Write-Host "`nProcessing molecules..." -ForegroundColor Yellow

foreach ($molecule in $molecules) {
    $moleculeName = $molecule.name
    $packName = $molecule.pack
    
    Write-Host "`n[$packName] $moleculeName" -ForegroundColor Cyan
    
    # Build the path to the molecule folder
    $moleculePath = Join-Path $AssetsBaseDir $packName
    $moleculePath = Join-Path $moleculePath $moleculeName
    
    Write-Host "  Looking in: $moleculePath" -ForegroundColor DarkGray
    
    # Check if folder exists
    if (-not (Test-Path $moleculePath)) {
        Write-Host "  [WARNING] Folder not found!" -ForegroundColor Red
        $missingCount++
        continue
    }
    
    # Find all JPG/JPEG images
    $imageFiles = Get-ChildItem -Path $moleculePath -File | 
                  Where-Object { $_.Extension -match '^\.(jpg|jpeg)$' } |
                  Sort-Object Name
    
    Write-Host "  Files found: $($imageFiles.Count)" -ForegroundColor Gray
    
    if ($imageFiles.Count -eq 0) {
        Write-Host "  [WARNING] No images in folder - clearing array" -ForegroundColor Yellow
        $molecule.images = @()
        $updatedCount++
        continue
    }
    
    # Build new image paths array (completely replace old array)
    $newImagePaths = @()
    foreach ($img in $imageFiles) {
        $relativePath = "assets/$packName/$moleculeName/$($img.Name)"
        $newImagePaths += $relativePath
    }
    
    # Display changes
    Write-Host "  Old: $($molecule.images.Count) images" -ForegroundColor DarkGray
    Write-Host "  New: $($newImagePaths.Count) images" -ForegroundColor DarkGray
    
    # Compare arrays
    $oldImagesStr = ($molecule.images | Sort-Object) -join "|"
    $newImagesStr = ($newImagePaths | Sort-Object) -join "|"
    
    if ($oldImagesStr -ne $newImagesStr) {
        Write-Host "  [UPDATED] Changes detected" -ForegroundColor Green
        $molecule.images = $newImagePaths
        $updatedCount++
    }
    else {
        Write-Host "  [NO CHANGE] Already in sync" -ForegroundColor DarkGray
        $unchangedCount++
    }
}

# 5. Save updated JSON
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Updated:   $updatedCount" -ForegroundColor Green
Write-Host "  Unchanged: $unchangedCount" -ForegroundColor Gray
Write-Host "  Missing:   $missingCount" -ForegroundColor $(if ($missingCount -gt 0) { "Yellow" } else { "Gray" })

if ($updatedCount -gt 0) {
    try {
        Write-Host "`nSaving changes to JSON..." -ForegroundColor Yellow
        $jsonString = $jsonContent | ConvertTo-Json -Depth 10
        $jsonString | Out-File -FilePath $JsonFilePath -Encoding UTF8 -Force
        
        Write-Host "[SUCCESS] molecules.json updated successfully!" -ForegroundColor Green
        Write-Host "Output: $JsonFilePath" -ForegroundColor Gray
    }
    catch {
        Write-Error "Failed to write JSON file: $_"
        exit 1
    }
}
else {
    Write-Host "`n[INFO] No changes needed" -ForegroundColor Cyan
}

Write-Host "`n[DONE]" -ForegroundColor Green