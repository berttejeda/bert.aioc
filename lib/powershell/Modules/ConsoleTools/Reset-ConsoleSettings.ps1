function Reset-ConsoleSettings {
    
    $ConsoleXMLPath = "$($env:APPDATA)\Console\console.xml"
    Write-Host $i18nMessage
    If (Test-Path $ConsoleXMLPath){
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.reset)))
        Remove-Item $ConsoleXMLPath
    }
}

Set-Alias -Name console.reset.settings -Value Reset-ConsoleSettings
