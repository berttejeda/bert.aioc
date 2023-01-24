function Stat-App{
    param(
        [Parameter(Mandatory=$true)]$Name
        )      
    if (Get-Command "$($Name)" -ErrorAction SilentlyContinue){
        return $True
    } else {
        return $False
    }
}