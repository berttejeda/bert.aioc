Function Destroy-Machine {
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
        If ($MachineIsRegistered){
            if (!$Force){
                $proceed = Read-Host $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString prompt.destroy)))
                if ($proceed.tolower() -ne 'y') {
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.no_destroy))) -Logfiles $MachineObj.logfile
                    return
                }
            }
            try { 
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.destroy))) -Logfiles $MachineObj.logfile
                if ($Force){
                    Stop-Machine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -Force
                } else {
                    Stop-Machine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -WaitForShutdown
                }
                &"$($MachineObj.vars.provider.type)`.destroy" -Machine $MachineObj.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope
            } catch {
                throw $_
            }
        } else {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.not_registered)))
        }
    }
}

Set-Alias -Name machine.destroy -Value Destroy-Machine
Set-Alias -Name machine.destroy.aio -Value Destroy-Machine