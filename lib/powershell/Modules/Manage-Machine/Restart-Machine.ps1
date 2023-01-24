Function Restart-Machine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",
    [Parameter(Mandatory=$False,Position=3)]
    [Alias('t')]
    $WaitPeriod=10
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    If ($MachineName.name){
        $MachineObjects = List-Machine $MachineName.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    } Else {
        $MachineObjects = List-Machine $MachineName -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    }

    ForEach ($MachineObj in $MachineObjects) {
        $MachineIsRegistered = $MachineObj.Availability -in @("Created","Ready")
        If ($MachineIsRegistered){
            Stop-Machine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment
            Start-Sleep $WaitPeriod
            Start-Machine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment
        } else {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.not_registered)))
        }
    }
}

Set-Alias -Name machine.restart  -Value Restart-Machine 
Set-Alias -Name machine.restart.aio  -Value Restart-Machine