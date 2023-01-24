Function Configure-Machine {
    param(
        [Parameter(Mandatory=$false,Position=0)]$MachineName,
        [Parameter(Mandatory=$true,Position=1)]$InitTasksFile,
        [Alias('env')]
        $MachineEnvironment=$Settings.environment.current.path,
        [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
        $EnvironmentScope="Local",
        [Alias('dry')]
        [Parameter(Mandatory=$false,Position=3)]$DryRun
        )    

    begin {

        Invoke-Command -ScriptBlock $Global:InvocationTrace
        
        if (!$MachineName.name){
            $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
        } else{
            $MachineObj = $MachineName
        }

        try {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.clearing_logfile)))
            '' > "$($MachineObj.logfile)"
        } catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.clearing_logfile)))
        }
    }

    process{

        if ($DryRun){
            Invoke-InitTask -MachineName $MachineObj -TaskName $host_task.name -MachineEnvironment $MachineObj.environment -InitTasksFile $InitTasksFile -EnvironmentScope $EnvironmentScope -DryRun
        } else {
            Invoke-InitTask -MachineName $MachineObj -TaskName $host_task.name -MachineEnvironment $MachineObj.environment -InitTasksFile $InitTasksFile -EnvironmentScope $EnvironmentScope -InitialRun
        }
    }
    end {
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.finished_bootstrap))) -Logfiles $MachineObj.logfile
    }
}