Push-Location $PSScriptRoot

# Spinnaker SDK ships the camera driver. Bonsai cannot see the Blackfly without
# it, and only this exact version works, so check before spending time on the
# package restore. This is a warning rather than a hard stop: the workflow still
# opens without a camera attached.
$requiredSpinnaker = '4.2.0.83'
$spinnakerUrl = 'https://www.teledynevisionsolutions.com/support/support-center/software-firmware-downloads/iis/spinnaker-sdk-download/spinnaker-sdk--download-files/'

$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$spinnaker = Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like '*Spinnaker*' } |
    Select-Object -First 1

if (-not $spinnaker) {
    Write-Host ""
    Write-Warning "Spinnaker SDK was not found."
    Write-Host "  Bonsai will start, but it will not detect the camera."
    Write-Host "  Install version $requiredSpinnaker from:"
    Write-Host "  $spinnakerUrl"
    Write-Host "  The download page defaults to the latest release, so pick the version deliberately."
    Write-Host ""
}
elseif ($spinnaker.DisplayVersion -ne $requiredSpinnaker) {
    Write-Host ""
    Write-Warning "Spinnaker SDK $($spinnaker.DisplayVersion) is installed, but this project needs $requiredSpinnaker."
    Write-Host "  A different version can stop Bonsai detecting the camera, or make it crash."
    Write-Host "  $spinnakerUrl"
    Write-Host ""
}
else {
    Write-Host "Spinnaker SDK $requiredSpinnaker found."
}

# The video is encoded by ffmpeg.exe, which Bonsai.FFmpeg starts from PATH. The workflow
# uses Intel Quick Sync (h264_qsv), so also check this machine can actually encode with it.
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    Write-Host ""
    Write-Warning "FFmpeg was not found on PATH."
    Write-Host "  Recording will stop at once with 'The system cannot find the file specified'. Install it with:"
    Write-Host "  winget install --id Gyan.FFmpeg -e"
    Write-Host "  then open a new window so PATH is refreshed, and run this setup again."
    Write-Host ""
}
else {
    & $ffmpeg.Source -v error -f lavfi -i color=black:s=320x240 -frames:v 1 -c:v h264_qsv -f null - 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "FFmpeg found, Intel Quick Sync encoding works."
    }
    else {
        Write-Host ""
        Write-Warning "FFmpeg is installed, but Intel Quick Sync (h264_qsv) does not work on this machine."
        Write-Host "  Switch the video encoder to x264 as described under 'Video encoding' in Software/README.md."
        Write-Host ""
    }
}

# The UclOpen packages are not on nuget.org, so the restore below fails with an
# unhelpful NuGet error if this folder is missing.
$localPackages = Join-Path $PSScriptRoot '../local_packages'
if (-not (Test-Path $localPackages) -or -not (Get-ChildItem $localPackages -Filter *.nupkg -ErrorAction SilentlyContinue)) {
    Write-Warning "No packages found in local_packages/. The restore will fail."
    Write-Host "  These are versioned in the repository. Check the clone is complete."
    Write-Host ""
}

if (!(Test-Path "./Bonsai.exe")) {
    $release = "https://github.com/bonsai-rx/bonsai/releases/latest/download/Bonsai.zip"
    $configPath = "./Bonsai.config"
    if (Test-Path $configPath) {
        [xml]$config = Get-Content $configPath
        $bootstrapper = $config.PackageConfiguration.Packages.Package.where{$_.id -eq 'Bonsai'}
        if ($bootstrapper) {
            $version = $bootstrapper.version
            $release = "https://github.com/bonsai-rx/bonsai/releases/download/$version/Bonsai.zip"
        }
    }
    Write-Host "Downloading Bonsai..."
    Invoke-WebRequest $release -OutFile "temp.zip"
    Move-Item -Path "NuGet.config" "temp.config" -ErrorAction SilentlyContinue
    Expand-Archive "temp.zip" -DestinationPath "." -Force
    Move-Item -Path "temp.config" "NuGet.config" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "temp.zip"
}

Write-Host "Restoring Bonsai packages..."
& .\Bonsai.exe --no-editor

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Setup complete. Open Bonsai, then File -> Open -> Behaviour_Box.bonsai"
    Write-Host "Do not launch the workflow file directly: this project relies on compatibility patches."
}
else {
    Write-Warning "Bonsai exited with code $LASTEXITCODE. The package restore may not have completed."
}

Pop-Location
