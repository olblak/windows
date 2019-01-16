Function Get-Jenkins([String] $jenkinsVersion, [String] $outputPath='.') {
    $isLts = $jenkinsVersion.Split('.').Length -gt 2

    $warUrl = "http://mirrors.jenkins.io/war/${jenkinsVersion}/jenkins.war"
    $warSha256Url = "http://mirrors.jenkins.io/war/${jenkinsVersion}/jenkins.war.sha256"

    if($isLts) {
        $warUrl = "http://mirrors.jenkins.io/war-stable/${jenkinsVersion}/jenkins.war"
        $warSha256Url = "http://mirrors.jenkins.io/war-stable/${jenkinsVersion}/jenkins.war.sha256"
    }
    
    $localWar = (Join-Path $outputPath 'jenkins.war')
    $localSha256 = (Join-Path $outputPath 'jenkins.war.sha256')

    Invoke-WebRequest -Uri $warUrl -OutFile $localWar
    Invoke-WebRequest -Uri $warSha256Url -OutFile $localSha256
    
    $computedHash = (Get-FileHash -Algorithm SHA256 -Path $localWar).Hash.ToString().ToLower()
    $specifiedHash = (Get-Content $localSha256 | %{ $_.Split(' ')[0]; }).ToLower()

    if($computedHash -ne $specifiedHash) {
        Write-Error 'Hashes for jenkins.war does not match!'
        exit 1
    }
}
