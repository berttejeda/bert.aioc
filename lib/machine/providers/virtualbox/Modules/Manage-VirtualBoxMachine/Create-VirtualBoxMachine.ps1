Function Create-VirtualBoxMachine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",
    [switch]$DryRun
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

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.validations.running)))
    
    if (!$MachineObj.vars.provider.type){
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.provider)))
    }
    
    if (-not $isLinux){
        $ValidationsFile = "$($Settings.machine.providers.dir)\$($MachineObj.vars.provider.type)\etc\validations.yaml"
    } else {
        $ValidationsFile = "$($Settings.machine.providers.dir)/$($MachineObj.vars.provider.type)/etc/validations.yaml"
    }

    if (Test-Path "$ValidationsFile"){
        Run-Tests "$ValidationsFile" -FailOnError -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope
    } else {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.validations.notfound)))
    }

    if ($DryRun){
        Initialize-Machine -MachineName $MachineObj -MachineSettings $MachineObj -EnvironmentScope $EnvironmentScope -Start -Create -DryRun
    } else {
        Initialize-Machine -MachineName $MachineObj -MachineSettings $MachineObj -EnvironmentScope $EnvironmentScope -Start -Create
    }
}

Function virtualbox.create.aio {
    param(
    [switch]$DryRun
    )
    if ($DryRun){
        Create-VirtualBoxMachine -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $Settings.environment.default.path -DryRun
    } else {
        Create-VirtualBoxMachine -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $Settings.environment.default.path
    }    
}

Set-Alias -Name virtualbox.create -Value Create-VirtualBoxMachine
