#!/usr/bin/pwsh
[CmdletBinding()]
Param(
    [Parameter(Position=0)]
    [String] $releaseType = "weekly",
    [Parameter(Position=1)]
    [String] $version
)

$currDir = Split-Path -parent $MyInvocation.MyCommand.Definition

$helperOutputFile = (Join-Path $currDir (Join-Path "tools" "helpers.ps1"))
if (Test-Path $helperOutputFile) {
    Remove-Item -Force $helperOutputFile
}

$verificationOutputFile = (Join-Path $currDir (Join-Path "legal" "VERIFICATION.txt"))
if (Test-Path $verificationOutputFile) {
    Remove-Item -Force $verificationOutputFile
}

$changelog = "changelog"
$suffix = "-weekly"
$zipLoc = "windows"

if($version -eq "") {
    Write-Error "Missing version parameter!"
}

if($releaseType -eq "lts") {
    $changelog = "changelog-stable"
    $suffix = "-lts"
    $releaseType = "LTS"
    $zipLoc = "windows-stable"
}

$shaUrl = "http://mirrors.jenkins-ci.org/$($zipLoc)/jenkins-$($version).zip.sha256"
$shaFile = [System.IO.Path]::GetTempFileName()

Invoke-WebRequest -Uri $shaUrl -OutFile $shaFile

$shaContents = (Get-Content $shaFile)

$sha = ($shaContents -split "\s+")[0]

$helpersFile = Get-Content (Join-Path $currDir (Join-Path "templates" "helpers.ps1.in"))
$helpersFile = $helpersFile -replace "%ZIP_LOC%", $zipLoc
$helpersFile = $helpersFile -replace "%CHECKSUM%", $sha
Set-Content -Path $helperOutputFile -Value $helpersFile -Encoding Ascii

$verificationFile = Get-Content (Join-Path $currDir (Join-Path "templates" "VERIFICATION.txt.in"))
$verificationFile = $verificationFile -replace "%ZIP_LOC%", $zipLoc
$verificationFile = $verificationFile -replace "%CHECKSUM%", $sha
$verificationFile = $verificationFile -replace "%VERSION%", $version
Set-Content -Path $verificationOutputFile -Value $verificationFile -Encoding Ascii

& choco pack --version=$version changelog=$changelog suffix=$suffix releaseType=$releaseType
