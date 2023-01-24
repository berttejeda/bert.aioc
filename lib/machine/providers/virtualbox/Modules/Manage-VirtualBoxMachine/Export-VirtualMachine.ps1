Function Export-VirtualBoxMachine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=3)]
    [Alias('o')]
    $ExportOutputPath,        
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=4)]
    [Alias('p')]
    $ExportProductDescription="VirtualBox Export",    
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=5)]
    [Alias('u')]
    $ExportProductURL="",
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=6)]
    [Alias('v')]
    $ExportVendor="",
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=7)]
    [Alias('vu')]
    $ExportVendorURL="",
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=8)]
    [Alias('d')]
    $ExportDescription="",    
    [switch]$Force
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

    if (-not $ExportOutputPath){
        $ExportOutputPath = "$($MachineObj.name).ova"
    }

    Stop-Machine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -WaitForShutdown

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.exporting))) -debug

    &$virtualbox.defaults.VboxManagePath export $MachineObj.name -o $ExportOutputPath --ovf10 --vsys 0 --product "$ExportProductDescription" --producturl "$ExportProductURL" --vendor "$ExportVendor" --vendorurl "$ExportVendorURL" --description "$ExportDescription"

    If ($LASTEXITCODE -ne 0) {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed)))
    }
}

Function virtualbox.export.aio {
    Export-VirtualBoxMachine -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $virtualbox.defaults.default_environment
}

 Set-Alias -Name machine.export -Value Export-VirtualBoxMachine
 Set-Alias -Name virtualbox.export -Value Export-VirtualBoxMachine