Function Start-Machine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local"
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    If ($MachineName.name){
        $MachineObjects = List-Machine $MachineName.name -MachineEnvironment $MachineEnvironment -AsObject -EnvironmentScope $EnvironmentScope
    } Else {
        $MachineObjects = List-Machine $MachineName -MachineEnvironment $MachineEnvironment -AsObject -EnvironmentScope $EnvironmentScope
    }

    ForEach ($MachineObj in $MachineObjects) {
        $MachineIsRegistered = $MachineObj.Availability -in @("Created","Ready")
        
        If ($MachineIsRegistered){
            $MachineIsRunning = $MachineObj.State -in @("Running","Ready")
            If (-Not $MachineIsRunning){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.starting)))
                &"$($MachineObj.vars.provider.type)`.start" -Machine $($MachineObj.name) -MachineEnvironment $MachineEnvironment -MachineState $($MachineObj.State)

            } else {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.is_running)))
            }
        } else {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.no_crr)))
        }    
    }


}

Set-Alias -Name machine.start  -Value Start-Machine 
Set-Alias -Name machine.start.aio  -Value Start-Machine