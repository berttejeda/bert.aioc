function Start-HotKeys {
    param(
        [Parameter(Mandatory=$true)]$path,
        [Parameter(Mandatory=$true)]$process,
        [Parameter(Mandatory=$true)]$AHKCompiler,
        [Parameter(Mandatory=$true)]$SourceFile,
        [Parameter(Mandatory=$true)]$OutputFile        
        )    
    if ( -Not $(Test-Path "$($path)")) {
        "Compiling Hotkeys Executable ..."
        &"$AHKCompiler" /in "$SourceFile" /out "$OutputFile"
        Start-Sleep 5
        "Starting Hotkeys Executable"
        Start-Process("$path")
    }
    if (-Not $(Get-Process -Name "$process" -Erroraction SilentlyContinue)){
        "Starting Hotkeys Executable"
        Start-Process("$($path)")
    }
}