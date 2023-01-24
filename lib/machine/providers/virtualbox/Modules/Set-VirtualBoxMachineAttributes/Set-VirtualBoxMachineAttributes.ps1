function Set-VirtualBoxMachineAttributes {

    param(
    [Parameter(Mandatory=$True,Position=0)]
    $MachineObj
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if ($IsWindows){
        $DefinitionFilePathParts = $($MachineObj.definition_file -Split("\\$($MachineObj.environment_name)\\",0))
        $DefinitionFileEnvFolderNonPosix = $DefinitionFileEnvFolder = $DefinitionFilePathParts[0]
        if ($DefinitionFileEnvFolder.Contains("$HOME")) {
            $DefinitionFileEnvFolder = $DefinitionFileEnvFolder -Replace("\\","/")
            $DefinitionFileEnvFolder = $DefinitionFileEnvFolder -Replace($("$HOME" -Replace("\\","/")), "")
            $DefinitionFileEnvFolder = '{0}/{1}_{2}' -f $virtualbox.defaults.shared_folders.mountpath,$virtualbox.defaults.shared_folders.prefix,$DefinitionFileEnvFolder.substring(1)

        }
        Invoke-Logger "Environment Folder is $DefinitionFileEnvFolder" -debug -MinimumLogLevel 2
        $DefinitionFilePathNonPosix = $DefinitionFilePathParts[-1]
        $DefinitionFilePath = $DefinitionFilePathParts[-1] -Replace("\\","/")
        $DefinitionFilePath = '{0}/{1}/{2}' -f $DefinitionFileEnvFolder,$MachineObj.environment_name,$DefinitionFilePath
    } else {
        $DefinitionFilePath = $($MachineObj.definition_file -Split("\\$($MachineObj.environment_name)\\",0))
    }
    Invoke-Logger "Definition File Posix Path is $DefinitionFilePath" -debug -MinimumLogLevel 2
    $ProgramDirPosixPath = '{0}/{1}_{2}' -f $virtualbox.defaults.shared_folders.mountpath,$virtualbox.defaults.shared_folders.prefix,$virtualbox.defaults.shared_folders.program_dir_name
    $EnvironmentsPosixPath = '{0}/{1}/{2}' -f $ProgramDirPosixPath,$Settings.defaults.InfrastructureFolderName,$Settings.defaults.EnvironmentFolderName
    $MachineObj['program_dir'] = $ProgramDirPosixPath
    Invoke-Logger "ProgramDir Posix Path is $ProgramDirPosixPath" -debug -MinimumLogLevel 2
    $MachineObj['program_dir_environments_posix_path'] = $EnvironmentsPosixPath
    Invoke-Logger "ProgramDir Environments Posix Path is $EnvironmentsPosixPath" -debug -MinimumLogLevel 2
    $MachineObj['environments_posix_path'] = $DefinitionFileEnvFolder
    Invoke-Logger "Definition Environments Posix Path is $DefinitionFileEnvFolder" -debug -MinimumLogLevel 2
    $MachineObj['environment_posix_path'] = "$DefinitionFileEnvFolder/$($MachineObj.environment_name)"
    Invoke-Logger "Definition Environment Posix Path is $($MachineObj['environment_posix_path'])" -debug -MinimumLogLevel 2
    $MachineObj['definition_posix_path'] = $DefinitionFilePath
    $MachineObj['DynamicInventorySpec'] = '{0}/{1}/{2}/{3}' -f $ProgramDirPosixPath,$Settings.defaults.ansible.dir,$Settings.defaults.ansible.files,$Settings.defaults.ansible.DynamicInventory
    Invoke-Logger "DynamicInventorySpec is $($MachineObj['DynamicInventorySpec'])" -debug -MinimumLogLevel 2

    If ($MachineObj.vars.inventory_spec){
        $MachineObj['InventorySpec'] = $MachineObj.vars.inventory_spec
    } ElseIf ($IsWindows) {
        $MachineObj['InventorySpec'] = Join-Path $DefinitionFileEnvFolderNonPosix $MachineObj.environment_name $virtualbox.inventory.defaults.spec
        $MachineObj['InventorySpecPosixPath'] = '{0}/{1}/{2}' -f $DefinitionFileEnvFolder,$($MachineObj.environment_name),$($virtualbox.inventory.defaults.spec)
    } Else {
        $MachineObj['InventorySpec'] = "$EnvironmentsPosixPath/$($MachineObj.environment_name)/$($virtualbox.inventory.defaults.spec)"
        $MachineObj['InventorySpecPosixPath'] = $MachineObj['InventorySpec']
    }

    Invoke-Logger "Machine InventorySpec is $($MachineObj['InventorySpec'])" -debug -MinimumLogLevel 2
    Invoke-Logger "Machine InventorySpec Posix Path is $($MachineObj['InventorySpecPosixPath'])" -debug -MinimumLogLevel 2

    return $MachineObj

}

 Set-Alias -Name virtualbox.set_attributes -Value Set-VirtualBoxMachineAttributes