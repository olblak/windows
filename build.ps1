[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String] $jenkinsVersion,
    
    [String] $msbuildPath = ''
)

$ErrorActionPreference = "Stop"

$isLts = $jenkinsVersion.Split('.').Length -gt 2

Remove-Item -Recurse -Force tmp

$warUrl = "http://mirrors.jenkins.io/war/${jenkinsVersion}/jenkins.war"
$warSha256Url = "http://mirrors.jenkins.io/war/${jenkinsVersion}/jenkins.war.sha256"

if($isLts) {
    $warUrl = "http://mirrors.jenkins.io/war-stable/${jenkinsVersion}/jenkins.war"
    $warSha256Url = "http://mirrors.jenkins.io/war-stable/${jenkinsVersion}/jenkins.war.sha256"
}

Invoke-WebRequest -Uri $warUrl -OutFile jenkins.war
Invoke-WebRequest -Uri $warSha256Url -OutFile jenkins.war.sha256

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
    
$computedHash = (Get-FileHash -Algorithm SHA256 -Path jenkins.war).Hash.ToString().ToLower()

$specifiedHash = (Get-Content jenkins.war.sha256 | %{ $_.Split(' ')[0]; }).ToLower()

if($computedHash -ne $specifiedHash) {
    Write-Error 'Hash does not match!'
    exit 1
} 

New-Item -ItemType Directory -Path tmp -Force -Confirm:$false | Out-Null

# get the components we need from the war file
Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead('jenkins.war')
$zip.Entries | where {$_.Name -like "jenkins-core-${jenkinsVersion}.jar"} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "tmp\core.jar", $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead('tmp\core.jar')
$zip.Entries | where {$_.Name -like 'jenkins.exe'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "tmp\jenkins.exe", $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead('tmp\core.jar')
$zip.Entries | where {$_.Name -like 'jenkins.xml'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "tmp\jenkins.xml", $true)}
$zip.Dispose()

# restore the Wix package
.\nuget restore -PackagesDirectory packages

# build the msi
msbuild jenkins.wixproj /p:DisplayVersion=$jenkinsVersion /p:Configuration=Release /verbosity:minimal
