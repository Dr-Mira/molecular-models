$jsonPath = "molecules.json"
$assetsPath = "assets"

# 1. Check if Ground Truth exists
if (-not (Test-Path $jsonPath)) {
    Write-Error "molecules.json not found! This script requires an existing JSON file to update."
    exit 1
}

# 2. Read the Ground Truth JSON
$jsonContent = Get-Content -Raw $jsonPath
# Force into an array even if there is only one item
$molecules = @($jsonContent | ConvertFrom-Json)

Write-Host "Reading molecules.json... Found $($molecules.Count) entries."

# 3. Iterate through existing entries and update ONLY images
foreach ($mol in $molecules) {
    # Construct the expected folder path based on JSON data
    # Assumes structure: assets/{pack}/{name}
    $folderPath = Join-Path $assetsPath $mol.pack
    $folderPath = Join-Path $folderPath $mol.name

    if (Test-Path $folderPath) {
        # Scan for current images in that folder
        $images = Get-ChildItem -Path $folderPath -Include *.jpg,*.jpeg -Recurse | Sort-Object Name
        
        if ($images.Count -gt 0) {
            # Generate new image paths
            $newImagePaths = $images | ForEach-Object { 
                ("assets/" + $mol.pack + "/" + $mol.name + "/" + $_.Name).Replace("\", "/") 
            }
            
            # Update the existing JSON object with the new file list
            $mol.images = $newImagePaths
            Write-Host "Updated images for: $($mol.name)"
        } else {
            Write-Warning "Folder exists but no images found for: $($mol.name)"
            $mol.images = @()
        }
    } else {
        Write-Warning "Folder not found for JSON entry: $($mol.name) (Expected at $folderPath)"
    }
}

# 4. Save the updated JSON back to file
$molecules | ConvertTo-Json -Depth 5 | Set-Content $jsonPath
Write-Host "molecules.json updated successfully."