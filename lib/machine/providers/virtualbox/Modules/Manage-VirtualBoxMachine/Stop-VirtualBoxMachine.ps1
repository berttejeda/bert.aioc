Function Stop-VirtualBoxMachine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,    
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",    
    [switch]$Force,
    [switch]$WaitForShutdown
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

    If ($Force.IsPresent){
        $PowerOffAction = "poweroff"
    } else {
        $PowerOffAction = "acpipowerbutton"
    }
    &$virtualbox.defaults.VboxManagePath controlvm $MachineObj.name $PowerOffAction
    If ($LASTEXITCODE -ne 0) {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed)))
    }
    If ($WaitForShutdown){
        Stat-VirtualBoxMachineCli $MachineObj $MachineObj.environment -UntilNotAvailable
    }
}

Function virtualbox.stop.aio {
    Stop-VirtualBoxMachine -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $virtualbox.defaults.default_environment
}

 Set-Alias -Name virtualbox.stop -Value Stop-VirtualBoxMachine