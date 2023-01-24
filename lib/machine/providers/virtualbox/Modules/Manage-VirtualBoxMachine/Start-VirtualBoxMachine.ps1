Function Start-VirtualBoxMachine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,    
    [Parameter(Mandatory=$True,Position=2)]$MachineState,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=3)]
    $EnvironmentScope="Local"
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if (-not $virtualbox.environment.VboxManageAvailable) {
        throw [System.Exception] $(Expand-String $virtualbox.i18n.enUS.General.errors.vbox_cli.not_found)
    }
    
    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else {
        $MachineObj = $MachineName
    }

    switch ($True){
        ($MachineState -eq "paused"){            
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.resume))) -debug
            &$virtualbox.defaults.VboxManagePath controlvm $MachineObj.name resume
            break
        }
        ($MachineState -eq "aborted") {
            &$virtualbox.defaults.VboxManagePath startvm $MachineObj.name --type headless
            break
        }
        default {
            &$virtualbox.defaults.VboxManagePath startvm $MachineObj.name --type headless
        }
    }
    If ($LASTEXITCODE -ne 0) {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.start)))
    }
}

Function virtualbox.start.aio {
    Start-VirtualBoxMachine -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $virtualbox.defaults.default_environment
}

Set-Alias -Name virtualbox.start -Value Start-VirtualBoxMachine