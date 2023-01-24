function Launch-App {
    param(
    [Parameter(Mandatory=$True,Position=0)]$AppName
    )    
    $AppPath = $Settings.apps.$AppName.path
    $Launcher = $Settings.apps.$AppName.launcher
    If (Test-Path $AppPath){
        If ($Launcher){
            &$Launcher
        } Else {
            &$AppPath
        }
    }
}
Set-Alias -Name app.launch -Value Launch-App


function List-Apps {
    ForEach ($App in $Settings.apps.Keys){
        Write-Host "$App - $($Settings.apps.$App.path)"
    }
}
Set-Alias -Name app.list -Value List-Apps
