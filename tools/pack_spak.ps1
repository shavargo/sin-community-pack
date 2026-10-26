<#
.SYNOPSIS
    Packs a directory structure into a SiN SPAK (.sin) archive file.

.DESCRIPTION
    Creates an authentic SiN 1 Multiplayer SPAK pack file compatible with
    SiN Gold, the retail engine, and the modernized sin-mp-engine.
    Conforms to the 128-byte directory entry layout:
      - 120-byte null-padded forward-slash path name
      - 4-byte little-endian file offset
      - 4-byte little-endian file length

.PARAMETER InputDir
    The root directory containing the folders (maps, models, textures, sound, etc.) to pack.
    Defaults to the parent directory of this script.

.PARAMETER OutputFile
    The destination .sin file. Defaults to "dist/pak9_community.sin".

.EXAMPLE
    pwsh ./tools/pack_spak.ps1
    pwsh ./tools/pack_spak.ps1 -InputDir . -OutputFile dist/pak9_community.sin
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$InputDir = "",

    [Parameter(Position = 1)]
    [string]$OutputFile = "dist/pak9_community.sin"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($InputDir)) {
    # Default to parent of tools directory
    $InputDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
} else {
    $InputDir = (Resolve-Path $InputDir).Path
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SiN SPAK Archive Packer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Input Directory:  $InputDir"
Write-Host "Output Archive:   $OutputFile"

# Asset folders to include in packing
$includeFolders = @(
    "decals",
    "demos",
    "dialog",
    "env",
    "gfx",
    "global",
    "huds",
    "layouts",
    "maps",
    "menus",
    "models",
    "music",
    "pics",
    "sound",
    "sprites",
    "textures"
)

# Collect all files to pack
$filesToPack = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($folder in $includeFolders) {
    $folderPath = Join-Path $InputDir $folder
    if (Test-Path $folderPath) {
        $found = Get-ChildItem -Path $folderPath -Recurse -File
        foreach ($f in $found) {
            # Normalize relative path to forward slashes
            $rel = $f.FullName.Substring($InputDir.Length).TrimStart('\', '/').Replace('\', '/')
            
            # SiN SPAK filename limit is 119 characters + 1 null terminator
            if ($rel.Length -ge 120) {
                Write-Warning "Skipping '$rel': relative path exceeds 119 characters ($($rel.Length))"
                continue
            }
            
            $filesToPack.Add([PSCustomObject]@{
                FullPath = $f.FullName
                PackName = $rel
                Length   = $f.Length
            })
        }
    }
}

# Sort deterministically by path name (case-insensitive) for reproducible builds
$filesToPack = [System.Collections.Generic.List[PSCustomObject]]($filesToPack | Sort-Object -Property PackName)

Write-Host "Found $($filesToPack.Count) files to pack." -ForegroundColor Green

if ($filesToPack.Count -eq 0) {
    Write-Error "No files found to pack. Aborting."
    exit 1
}

# Resolve output path
$outResolved = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile
} else {
    Join-Path $InputDir $OutputFile
}

$outDir = [System.IO.Path]::GetDirectoryName($outResolved)
if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path $outDir)) {
    [System.IO.Directory]::CreateDirectory($outDir) | Out-Null
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Open destination file stream
$fs = [System.IO.File]::Create($outResolved)
$bw = New-Object System.IO.BinaryWriter($fs)

try {
    # 1. Write placeholder header (12 bytes: 'SPAK', dirpos, dirlen)
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes("SPAK"))
    $bw.Write([int]0) # dirpos (placeholder)
    $bw.Write([int]0) # dirlen (placeholder)

    # 2. Write file data
    $entries = [System.Collections.Generic.List[PSCustomObject]]::new()
    $buffer = New-Object byte[] (64 * 1024) # 64KB copy buffer
    $processed = 0

    foreach ($item in $filesToPack) {
        $filePos = [int]$fs.Position
        $fileLen = [int]$item.Length

        $inStream = [System.IO.File]::OpenRead($item.FullPath)
        try {
            $bytesRemaining = $fileLen
            while ($bytesRemaining -gt 0) {
                $read = $inStream.Read($buffer, 0, [Math]::Min($buffer.Length, $bytesRemaining))
                if ($read -le 0) { break }
                $bw.Write($buffer, 0, $read)
                $bytesRemaining -= $read
            }
        } finally {
            $inStream.Close()
        }

        $entries.Add([PSCustomObject]@{
            Name    = $item.PackName
            FilePos = $filePos
            FileLen = $fileLen
        })

        $processed++
        if ($processed % 500 -eq 0 -or $processed -eq $filesToPack.Count) {
            Write-Progress -Activity "Packing files into SPAK archive" -Status "$processed of $($filesToPack.Count)" -PercentComplete (($processed / $filesToPack.Count) * 100)
        }
    }

    # 3. Write directory entries at current position (dirpos)
    $dirPos = [int]$fs.Position
    $dirLen = $entries.Count * 128

    foreach ($e in $entries) {
        # 120-byte name field null-padded
        $nameBytes = [System.Text.Encoding]::ASCII.GetBytes($e.Name)
        $entryBytes = New-Object byte[] 120
        [Array]::Copy($nameBytes, $entryBytes, [Math]::Min($nameBytes.Length, 119))
        $bw.Write($entryBytes)

        # 4-byte position and 4-byte length
        $bw.Write([int]$e.FilePos)
        $bw.Write([int]$e.FileLen)
    }

    # 4. Seek back and write real dirpos and dirlen into header
    $fs.Seek(4, [System.IO.SeekOrigin]::Begin) | Out-Null
    $bw.Write([int]$dirPos)
    $bw.Write([int]$dirLen)

} finally {
    $bw.Flush()
    $bw.Close()
    $fs.Close()
}

$sw.Stop()

$finalInfo = Get-Item $outResolved
$hash = (Get-FileHash -Path $outResolved -Algorithm SHA256).Hash

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Build Complete!" -ForegroundColor Green
Write-Host " Archive:      $outResolved"
Write-Host " Size:         $([Math]::Round($finalInfo.Length / 1MB, 2)) MB ($($finalInfo.Length) bytes)"
Write-Host " Total Files:  $($entries.Count)"
Write-Host " Directory At: offset $dirPos ($dirLen bytes)"
Write-Host " Time Taken:   $([Math]::Round($sw.Elapsed.TotalSeconds, 2)) s"
Write-Host " SHA-256:      $hash"
Write-Host "========================================" -ForegroundColor Cyan
