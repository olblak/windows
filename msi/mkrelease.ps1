[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String] $jenkinsVersion,
    
    [String] $msbuildPath = ''
)

$ErrorActionPreference = "Stop"

Import-Module -Force ..\utilities.psm1

if(Test-Path tmp) {
    Remove-Item -Recurse -Force tmp
}

New-Item -ItemType Directory -Path tmp -Force -Confirm:$false | Out-Null

$currDir = Split-Path -parent $MyInvocation.MyCommand.Definition

Write-Host "Retrieving Jenkins WAR file $jenkinsVersion"
Get-Jenkins $jenkinsVersion (Join-Path $currDir 'tmp')

if($msbuildPath -ne '') {
    $env:PATH = [String]::Join(';', $env:PATH, [System.IO.Path]::GetDirectoryName($msbuildPath))
}

Write-Host "Extracting components"
# get the components we need from the war file
Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'jenkins.war'))
$zip.Entries | where {$_.Name -like "jenkins-core-${jenkinsVersion}.jar"} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "core.jar"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'core.jar'))
$zip.Entries | where {$_.Name -like 'jenkins.exe'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "jenkins.exe"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'core.jar'))
$zip.Entries | where {$_.Name -like 'jenkins.xml'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "jenkins.xml"), $true)}
$zip.Dispose()

Write-Host "Restoring packages before build"
# restore the Wix package
.\nuget restore -PackagesDirectory packages

Write-Host "Building MSI"
# build the msi
msbuild jenkins.wixproj /p:DisplayVersion=$jenkinsVersion /p:Configuration=Release
