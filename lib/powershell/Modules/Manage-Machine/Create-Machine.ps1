Function Create-Machine {

    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",    
    [switch]$DryRun
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    If ($MachineName.name){
        $MachineObjects = List-Machine $MachineName.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    } Else {
        $MachineObjects = List-Machine $MachineName -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    }

    ForEach ($MachineObj in $MachineObjects) {
        $MachineIsRegistered = $MachineObj.Availability -in @("Created","Ready")

        if (!$MachineIsRegistered){

            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.valid)))

            if ($DryRun){
                &"$($MachineObj.vars.provider.type)`.create" -Machine $MachineObj.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -DryRun
            } else {
                &"$($MachineObj.vars.provider.type)`.create" -Machine $MachineObj.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope
            }
        } else {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.registered)))
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.starting)))
            Start-Machine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope
        }
    }

}

Set-Alias -Name machine.create -Value Create-Machine
Set-Alias -Name machine.create.aio -Value Create-Machine