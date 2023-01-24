function Get-OSInfo {
    $name=(Get-CimInstance Win32_OperatingSystem).caption
    $bit=(Get-CimInstance Win32_OperatingSystem).OSArchitecture
    $vert = " Version:"
    $ver=(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
    $buildt = " Build:"
    $build= (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").BuildLabEx -match '^[0-9]+\.[0-9]+' |  % { $matches.Values }
    $installdate = ([datetime]'1/1/1970').AddSeconds($(get-itemproperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion").installdateate)
    Write-host $installdate
    Write-Host $name, $bit, $vert, $ver, $buildt, $build, $installdate
}