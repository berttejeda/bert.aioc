Function Stat-MachineCLI {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local", 
    [switch]$UseGuestControl=$False
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    If ($MachineName.name){
        $MachineObj = List-Machine $MachineName.name -MachineEnvironment $MachineEnvironment -AsObject -EnvironmentScope $EnvironmentScope
    } Else {
        $MachineObj = List-Machine $MachineName -MachineEnvironment $MachineEnvironment -AsObject -EnvironmentScope $EnvironmentScope
    }

    $MachineIsRegistered = $MachineObj.Availability -in @("Created","Ready")    

    If ($MachineIsRegistered){
        $MachineIsRunning = $MachineObj.State -in @("Running","Ready", "Pingable")
        If ($MachineIsRunning){        
            If ($UseGuestControl){
                Invoke-Expression "$($MachineObj.vars.provider.type)`.stat.cli -Machine $($MachineObj.name) -MachineEnvironment $MachineEnvironment -UseGuestControl"
            } else {
                Invoke-Expression "$($MachineObj.vars.provider.type)`.stat.cli -Machine $($MachineObj.name) -MachineEnvironment $MachineEnvironment"
            }
        } else {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.not_running)))
        }
    } else {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.not_registered)))
    }
}

Function machine.stat.cli.aio {
    Stat-MachineCLI -MachineName $Settings.defaults.aiomachine -MachineEnvironment $Settings.environment.current.path
}

Set-Alias -Name machine.stat.cli  -Value Stat-MachineCLI 
Set-Alias -Name machine.stat.cli.aio  -Value Stat-MachineCLI