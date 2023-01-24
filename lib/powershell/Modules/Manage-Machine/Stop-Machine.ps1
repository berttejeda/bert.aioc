Function Stop-Machine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",    
    [switch]$Force,
    [switch]$WaitForShutdown
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
            $MachineIsRunning = $MachineObj.State -in @("Running","Ready", "Pingable")
            If ($MachineIsRunning){
                If ($Force.IsPresent){
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.force_stop)))
                    Invoke-Expression "$($MachineObj.vars.provider.type)`.stop -Machine $($MachineObj.name) -MachineEnvironment $MachineEnvironment -Force"
                } else {
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.stop)))
                    If ($WaitForShutdown.IsPresent) {
                        Invoke-Expression "$($MachineObj.vars.provider.type)`.stop -Machine $($MachineObj.name) -MachineEnvironment $MachineEnvironment -WaitForShutdown"
                    } else {
                        Invoke-Expression "$($MachineObj.vars.provider.type)`.stop -Machine $($MachineObj.name) -MachineEnvironment $MachineEnvironment"
                    }
                }
            } else {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.not_running)))
            }
        } else {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.no_crr)))
        }
    }

}

Set-Alias -Name machine.stop  -Value Stop-Machine 
Set-Alias -Name machine.stop.aio  -Value Stop-Machine