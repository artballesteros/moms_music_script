# Powershell script to download yt-dlp and ffmpeg for Windows from GitHub and extract ffmpeg

$result = $true

# Set the download directory to the current directory
$downloadDir = Get-Location
$result = $result -and $?

# URL for the latest yt-dlp Windows release
$ytDlpUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"

# URL for the ffmpeg Windows build (64-bit, change to win32-gpl for 32-bit)
$ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

# Download yt-dlp
if (-not (Test-Path ".\yt-dlp.exe")) {
    Invoke-WebRequest -Uri $ytDlpUrl -OutFile "$downloadDir\yt-dlp.exe"
    $result = $result -and $?
} else {
    Write-Output "yt-dlp.exe already exists. Skipping download."
}

# Download ffmpeg (compressed as zip archive)
if (-not (Test-Path ".\ffmpeg.exe")) {
    Invoke-WebRequest -Uri $ffmpegUrl -OutFile "$downloadDir\ffmpeg.zip"
    $result = $result -and $?

    # Extract ffmpeg.zip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$downloadDir\ffmpeg.zip", $downloadDir)
    $result = $result -and $?

    # Move ffmpeg binary to current directory (don't care about version right now...)
    Move-Item "$downloadDir\ffmpeg-6.0-essentials_build\bin\ffmpeg.exe" ".\ffmpeg.exe"
    $result = $result -and $?

    # Delete the ffmpeg.zip after extraction
    Remove-Item "$downloadDir\ffmpeg.zip"
    $result = $result -and $?

    # Delete the other extracted stuff
    Remove-Item "$downloadDir\ffmpeg-6.0-essentials_build" -Recurse -Force
    $result = $result -and $?
} else {
    Write-Output "ffmpeg.exe already exists. Skipping download."
}

# Check final result and download music if successful
if ($result) {
    Write-Output "All dependencies installed! Downloading music!"

    # Define the path to the yt-dlp executable
    $youtubeDLPath = ".\yt-dlp.exe"

    # Define the path to the file containing YouTube URLs
    $urlFilePath = ".\moms_urls.txt"

    # Read the URLs and song names from the file
    $lines = Get-Content $urlFilePath

    # Iterate through each line
    foreach ($line in $lines) {
        # Split the line into URL and song name
        $url, $songName = $line -split '\s+', 2

        # Build the output filename using the song name and audio extension
        $outputFilename = "downloads\$songName.mp3"

        # Check if the output file already exists
        if (Test-Path $outputFilename) {
            Write-Host "Skipping download. File already exists: $songName"
            continue
        }

        # Build the yt-dlp command with audio format, quality, and extraction
        $youtubeDLCommand = "& '$youtubeDLPath' --no-playlist -x --audio-format mp3 -o '$outputFilename' $url"

        # Execute the yt-dlp command
        try {
            Invoke-Expression $youtubeDLCommand
            Write-Host "Downloaded audio: $songName"
        } catch {
            Write-Host "Failed to download audio: $songName"
            Write-Host $_.Exception.Message
        }
    }
} else {
    Write-Output "One or more commands failed! No downloading will begin..."
}