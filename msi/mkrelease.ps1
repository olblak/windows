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

Get-Jenkins $jenkinsVersion (Join-Path $currDir 'tmp')

# check for msbuild in the path already
if(-not (Find-Command -Name msbuild.exe)) {
    if($msbuildPath -eq [String]::Empty) {
        $_VSWHERE = [System.IO.Path]::Combine(${env:ProgramFiles(x86)}, 'Microsoft Visual Studio\Installer\vswhere.exe')
        $_VSINSTPATH = ''

        if([System.IO.File]::Exists($_VSWHERE)) {
            $_VSINSTPATH = & "$_VSWHERE" -latest -requires Microsoft.Component.MSBuild -property installationPath
        } else {
            Write-Error "Visual Studio 2017 15.2 or later is required"
            Exit 1
        }

        if(-not [System.IO.Directory]::Exists($_VSINSTPATH)) {
            Write-Error "Could not determine installation path to Visual Studio"
            Exit 1
        }

        if([System.IO.File]::Exists([System.IO.Path]::Combine($_VSINSTPATH, 'MSBuild\15.0\Bin\MSBuild.exe'))) {
            $env:PATH = [String]::Join(';', $env:PATH, [System.IO.Path]::Combine($_VSINSTPATH, 'MSBuild\15.0\Bin'))
        }
    } else {
        $env:PATH = [String]::Join(';', $env:PATH, [System.IO.Path]::GetDirectoryName($msbuildPath))
    }
}



# get the components we need from the war file
Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'jenkins.war'))
$zip.Entries | where {$_.Name -like "jenkins-core-${jenkinsVersion}.jar"} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "core.jar"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'core.jar'))
$zip.Entries | where {$_.Name -like 'jenkins.exe'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "jenkins.exe"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'core.jar'))
$zip.Entries | where {$_.Name -like 'jenkins.xml'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "jenkins.xml"), $true)}
$zip.Dispose()

# restore the Wix package
.\nuget restore -PackagesDirectory packages

# build the msi
msbuild jenkins.wixproj /p:DisplayVersion=$jenkinsVersion /p:Configuration=Release /verbosity:minimal
