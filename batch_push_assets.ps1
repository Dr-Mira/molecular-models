# batch_push_assets.ps1

# Change directory to the assets folder which is the actual git repository for assets
Set-Location -Path "assets"

# --- STEP 1: NUKE HISTORY AND INITIAL COMMIT ---
Write-Host "WARNING: This will completely replace your 'molecular-models-assets' GitHub history with a single clean commit." -ForegroundColor Yellow
$confirm = Read-Host "Proceed with history nuke for ASSETS? (y/n)"
if ($confirm -ne 'y') { exit }

Write-Host "Creating clean branch in assets repo..."
git checkout --orphan latest_branch
git add .

# Unstage asset packs for batching
Write-Host "Unstaging asset packs for batching..."
git reset pack_*

git commit -m "Initial commit (Clean History - Compressed Assets)"
git branch -D main
git branch -m main

Write-Host "Force pushing to GitHub to nuke history in 'molecular-models-assets'..."
git push -f origin main

# --- STEP 2: BATCH PUSH ASSET PACKS ---
Write-Host "Starting batch push of asset packs..." -ForegroundColor Cyan

$packs = Get-ChildItem pack_* | Select-Object -ExpandProperty Name
$total = $packs.Count
$count = 1

foreach ($pack in $packs) {
    Write-Host "[$count/$total] Adding and pushing $pack..." -ForegroundColor Green
    git add "$pack"
    git commit -m "Add asset pack: $pack"
    git push origin main
    
    if ($count -lt $total) {
        Write-Host "Waiting 60 seconds before next pack to avoid timeouts/rate limits..." -ForegroundColor Gray
        Start-Sleep -Seconds 60
    }
    $count++
}

Write-Host "Batch push complete!" -ForegroundColor Cyan
Set-Location -Path ".."
