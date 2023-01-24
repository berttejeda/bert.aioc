function Invoke-GarbageCollection {

    $GlobalVarsToCleanUp=@(
        "EnvironmentFolder",
        "machine_workspace",
        "MachineDefinition",
        "MachineDefinitionFile",
        "MachineDefinitionSet",
        "MachineDir",
        "MachineObj",
        "VMachineState"
        "TaskObjects",
        "VagrantBox",
        "VagrantBoxDownloadDirectory",
        "VagrantBoxName",
        "VboxManage",
        "VboxManageHostAdapter",
        "VHDPath",
        "MachineAttributes"
    )

    $ErrorActionPreference = "SilentlyContinue"
    ForEach ($v in $GlobalVarsToCleanUp) {
        If (Get-Variable $v -scope Global){
            Remove-Variable $v -scope Global
        }
    }

}
