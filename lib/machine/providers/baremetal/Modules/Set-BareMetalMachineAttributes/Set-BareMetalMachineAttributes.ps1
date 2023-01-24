function Set-BareMetalMachineAttributes {

    param(
    [Parameter(Mandatory=$True,Position=0)]
    $MachineObj
    )    

    Invoke-Command -ScriptBlock $Global:InvocationTrace
    
    if ($IsWindows){
        $DefinitionFilePath = $($MachineObj.definition_file -Split("\\$($MachineObj.environment_name)\\",0))[-1] -Replace("\\","/")
    } else {
        $DefinitionFilePath = $($MachineObj.definition_file -Split("\\$($MachineObj.environment_name)\\",0))
    }

    $DefinitionFilePathStripped = $($MachineObj.definition_file -Split("\\$($MachineObj.environment_name)\\",0))[-1]
    $PosixPath = $DefinitionFilePathStripped -Replace("\\","/")
    $EnvironmentPosixPath = "$($MachineObj.environment_name)"
   
    $MachineObj['definition_posix_path'] = "$($Settings.defaults.InfrastructureFolderName)/$($Settings.defaults.EnvironmentFolderName)/$EnvironmentPosixPath/$PosixPath"

    If ($MachineObj.vars.inventory_spec){
        $MachineObj['InventorySpec'] = $MachineObj.vars.inventory_spec
    } ElseIf ($IsWindows) {
        $MachineObj['InventorySpec'] = "$($Settings.defaults.InfrastructureFolderName)/$($Settings.defaults.EnvironmentFolderName)/$($MachineObj.environment_name)/$($baremetal.inventory.defaults.spec)"
    } Else {
        $MachineObj['InventorySpec'] = "$EnvironmentsPosixPath/$($MachineObj.environment_name)/$($baremetal.inventory.defaults.spec)"
    }

    return $MachineObj

}

 Set-Alias -Name baremetal.set_attributes -Value Set-BareMetalMachineAttributes