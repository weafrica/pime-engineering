# Pushes this folder to a new GitHub repo, then you connect that repo to
# Vercel from vercel.com/new (see README.md section 4).
#
# Usage:
#   1. Create an EMPTY repo on github.com first (no README, no .gitignore).
#   2. Edit RepoPath and RemoteUrl below.
#   3. powershell -ExecutionPolicy Bypass -File push-to-github.ps1

# Where this folder (pime-engineering site) lives locally.
$RepoPath = "C:\Users\saule\Downloads\pime-engineering"

# Your new empty GitHub repo's URL, e.g.:
# https://github.com/yourusername/pime-engineering.git
$RemoteUrl = "https://github.com/YOUR-USERNAME/YOUR-REPO.git"

if (-not (Test-Path $RepoPath)) {
    Write-Error "Couldn't find '$RepoPath'. Edit RepoPath at the top of this script to point at the downloaded pime-engineering folder."
    exit 1
}

if ($RemoteUrl -like "*YOUR-USERNAME*") {
    Write-Error "Edit RemoteUrl at the top of this script first -- it's still the placeholder."
    exit 1
}

Push-Location $RepoPath
try {
    if (-not (Test-Path "$RepoPath\.git")) {
        git init
        git branch -M main
    }
    git add .
    git commit -m "Initial commit"
    git remote remove origin 2>$null
    git remote add origin $RemoteUrl
    git push -u origin main
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Pushed. Next: go to vercel.com/new and import this repo (see README.md section 4)."
