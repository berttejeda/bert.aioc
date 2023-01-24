Function Restart-VirtualBoxServices {
    param(
    [switch]$Force
    )

    $VBoxServices = Get-Service | Where-Object { $_.DisplayName -imatch '.*virtualbox.*'}
    $VBoxServices | ForEach-Object {
        $VBoxService = $_
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.restart.service)))
        try {
            Restart-Service -ErrorAction SilentlyContinue -Name $VBoxService.Name -ErrorVariable ErrRestart
            If ($?){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.restart.success))) -info
            } else {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.restart.generic))) -err
            }
        } catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.restart.exception))) -err
        }
    }

    If ($Force){
        $VBoxProcesses =  Get-Process | Where-Object {$_.Name -match '^VBox'}
        $VBoxProcesses | ForEach-Object {
            $VBoxProcess = $_
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.restart.proc.restarting)))
            try {
                Stop-Process -ErrorAction SilentlyContinue -Name $VBoxProcess.Name -ErrorVariable ErrRestart
                If ($?){
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.restart.proc.success)))
                } else {
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.restart.proc.generic))) -err
                }
            } catch {
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.restart.proc.exception))) -err
            }
        }        
    }
}

Set-Alias -Name virtualbox.service.restart -Value Restart-VirtualBoxServices