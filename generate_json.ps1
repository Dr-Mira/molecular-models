$assetsPath = "assets"
$molecules = @()

# Get all pack folders
$packs = Get-ChildItem -Path $assetsPath -Directory -Filter "pack_*"

foreach ($pack in $packs) {
    # Get all molecule folders inside the pack
    $molFolders = Get-ChildItem -Path $pack.FullName -Directory

    foreach ($molFolder in $molFolders) {
        $molName = $molFolder.Name.Replace("_", " ") # Prettify name slightly? Or keep raw? Let's keep raw folder name or try to capitalize. 
        # Actually user wants "reflect pack folders", so folder name is safe.
        # But let's Title Case it if possible? Powershell Get-Culture... maybe just Replace underscores with spaces for display, but keep ID?
        # Let's keep "name" as the folder name for now, but maybe add a "displayName"
        
        # Get images
        $images = Get-ChildItem -Path $molFolder.FullName -Include *.jpg,*.jpeg -Recurse
        # Sort images by name so _4, _5, _6 are in order
        $images = $images | Sort-Object Name

        if ($images.Count -gt 0) {
            $imagePaths = $images | ForEach-Object { ("assets/" + $pack.Name + "/" + $molFolder.Name + "/" + $_.Name).Replace("\", "/") }
            
            # Determine tags (try to read tags file)
            $tags = @()
            $tagFile = Get-ChildItem -Path $molFolder.FullName -Filter "*_tags.txt" | Select-Object -First 1
            if ($tagFile) {
                $tags = Get-Content $tagFile.FullName
                # Force to simple string array to avoid PS metadata serialization
                $tags = $tags | ForEach-Object { "$_" }
            }

            # Create object
            $molObj = [PSCustomObject]@{
                name = $molName
                pack = $pack.Name
                images = $imagePaths
                concepts = $tags
                category = $pack.Name
            }
            $molecules += $molObj
        }
    }
}

$molecules | ConvertTo-Json -Depth 5 | Set-Content "molecules.json"
Write-Host "Generated molecules.json with $($molecules.Count) molecules."
