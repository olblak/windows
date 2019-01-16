#!/usr/bin/pwsh
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String] $jenkinsVersion
)

$isLts = $jenkinsVersion.Split('.').Length -gt 2

Remove-Item -Recurse -Force bin

$currDir = Split-Path -parent $MyInvocation.MyCommand.Definition

$helperOutputFile = (Join-Path $currDir (Join-Path "tools" "helpers.ps1"))
if (Test-Path $helperOutputFile) {
    Remove-Item -Force $helperOutputFile
}

$verificationOutputFile = (Join-Path $currDir (Join-Path "legal" "VERIFICATION.txt"))
if (Test-Path $verificationOutputFile) {
    Remove-Item -Force $verificationOutputFile
}


$suffix = @("", "-stable")[$isLts]
$changelog = "changelog${suffix}"
$zipLoc = "windows${suffix}"
$releaseType = @("Weekly", "LTS")[$isLts]

if($jenkinsVersion -eq "") {
    Write-Error "Missing version parameter!"
}

$shaUrl = "http://mirrors.jenkins-ci.org/$($zipLoc)/jenkins-$($jenkinsVersion).zip.sha256"
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
$verificationFile = $verificationFile -replace "%VERSION%", $jenkinsVersion
Set-Content -Path $verificationOutputFile -Value $verificationFile -Encoding Ascii

if(-not (Get-Command choco)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

mkdir -Confirm:$false bin | Out-Null
& choco pack --version="$jenkinsVersion" id="jenkins${suffix}" changelog="$changelog" releaseType="$releaseType" --out="bin"
