function Invoke-InitTask() {

    param(
    [Parameter(Mandatory=$True,Position=0)]$MachineName,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('TaskID')]
    [string]$TaskName,
    [Parameter(Mandatory=$True,Position=2)]
    [Alias('env')]
    $MachineEnvironment,
    [Alias('TaskFile')]
    [Parameter(Mandatory=$True,Position=5)]$InitTasksFile,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=6)]
    $EnvironmentScope="Local",    
    [switch]$DryRun,
    [switch]$InitialRun,
    [switch]$ReInit,
    [switch]$ListTasks,
    [switch]$ListVerbose
    )

    begin {

        Invoke-Command -ScriptBlock $Global:InvocationTrace

        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.inittasksfile)))

        if (!$MachineName.name){
            $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
        } else{
            $MachineObj = $MachineName
        }
        
        # Derive tasks
        $Tasks = ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Path "$InitTasksFile" )
        # Append global init tasks
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.check_global_init)))
        ForEach ($Private:GlobalInitDir in $Settings.defaults.global_init_dirs){
            $GlobalInitFile = "$GlobalInitDir\$($MachineObj.vars.provider.type)\etc\$($Settings.machine.init_file_name)"
            if (Test-Path "$GlobalInitFile"){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.include_global_init)))
                $GlobalInitTasks = ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Path $GlobalInitFile)
                ForEach ($Task in $Tasks){
                    try {
                        $GlobalInitTasks += $Task
                    } catch {
                        $TaskErr = $_.Exception.Message
                    }
                }
                if ($TaskErr){                    
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.failed_adding_global_init))) -Warn
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.unsupported_init_operation))) -Warn
                } else {
                    $Tasks = $GlobalInitTasks
                }            
            }
        }

        if ($MachineObj.vars.init.tasks){
            ForEach ($Task in $Tasks){
                try {
                    $MachineObj.vars.init.tasks += $Task
                } catch {
                    $TaskErr = $_.Exception.Message
                }
            }
            if ($TaskErr){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.failed_add_mspec_init_tasks))) -Warn
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.unsupported_init_operation))) -Warn
            } else {
                $Tasks = $MachineObj.vars.init.tasks
            }
        }        
        # Append per-machine init tasks
        if ($MachineObj.vars.init.tasks){
            ForEach ($Task in $Tasks){
                try {
                    $MachineObj.vars.init.tasks += $Task
                } catch {
                    $TaskErr = $_.Exception.Message
                }
            }
            if ($TaskErr){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.failed_add_mspec_init_tasks))) -Warn
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.unsupported_init_operation))) -Warn
            } else {
                $Tasks = $MachineObj.vars.init.tasks
            }
        }
        if (!$HostTask -and $TaskName){
            if ($ReInit) {
                $TaskObjects = $Tasks
            } else {
                if($Settings.environment.ModernPS)
                {
                    $TaskDict = [ordered]@{}
                } else {
                    $TaskDict = @{}
                }
                $TaskNum = 0
                ForEach ($TaskObject in $Tasks){
                    $TaskHash = [math]::abs($ExecutionContext.InvokeCommand.ExpandString($TaskObject.name).gethashcode()) | Out-String
                    $TaskDict.Add($TaskHash.Trim(),"$TaskNum")
                    $TaskNum++
                }
                if ($TaskName -match '[\d]+-[\d]+') {
                    $TaskParts = $TaskName.split('-')
                    $TaskRange = $TaskParts[0]..$TaskParts[1]
                }
                if ($TaskRange) {
                    $TaskObjects = $Tasks | Where-Object{
                        (
                            $TaskDict["$([math]::abs($ExecutionContext.InvokeCommand.ExpandString($_.name).gethashcode()))"] -in $TaskRange -or `
                            [System.Convert]::ToBoolean($_.always_run)
                        )
                    }
                } else {
                    $TaskObjects = $Tasks | Where-Object{
                        (
                            "$([math]::abs($ExecutionContext.InvokeCommand.ExpandString($_.name).gethashcode()))" -eq $TaskName -or `
                            $TaskDict["$([math]::abs($ExecutionContext.InvokeCommand.ExpandString($_.name).gethashcode()))"] -eq $TaskName -or `
                            [System.Convert]::ToBoolean($_.always_run)
                        )
                    }
                }
            }
            $TasksThatAlwaysRun = $TaskObjects | Where-Object{ [System.Convert]::ToBoolean($_.always_run) }
            Switch ($True) {
               ($TaskObjects.length -lt $TasksThatAlwaysRun.length)  { throw [System.Exception] $ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.no_tasks_matching));break }
               ($TaskObjects.length -eq $TasksThatAlwaysRun.length)  { 
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.no_tasks_matching))) -Warn
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warning.no_tasks_matching_advise))) -Warn
                break 
                }
               default { break; }
            }
        } else {
            $TaskObjects = $Tasks
        }
    }

    process {

        if ($ListTasks){
            $tnum = 0
            if ($ListVerbose){
                try {
                    ForEach ($TaskObject in $TaskObjects){
                        $tn = $ExecutionContext.InvokeCommand.ExpandString($TaskObject.name)
                        $ti = [math]::abs($tn.gethashcode())
                        $tc = $TaskObject.command
                        Write-Host "Name: " -NoNewLine -ForegroundColor Green -BackgroundColor Black
                        Write-Host $tn
                        Write-Host "TaskID: " -NoNewLine -ForegroundColor Green -BackgroundColor Black
                        Write-Host $ti
                        Write-Host "TaskNumber: " -NoNewLine -ForegroundColor Green -BackgroundColor Black
                        Write-Host $tnum
                        Write-Host "Command:`n" -NoNewLine -ForegroundColor DarkYellow -BackgroundColor Black
                        Write-Host $tc
                        $tnum++
                    }
                    return $($TaskList)
                } catch {
                    throw [System.Exception] $ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed_derive_tasks))

                }  
            } else {
                $TaskList = "Name,TaskID,TaskNumber`n"
                try {
                    ForEach ($TaskObject in $TaskObjects){
                        $tn = $ExecutionContext.InvokeCommand.ExpandString($TaskObject.name)
                        $ti = [math]::abs($tn.gethashcode())
                        $TaskList = $TaskList + "$tn,$ti,$tnum`n"
                        $tnum++
                    }
                    return $($TaskList | ConvertFrom-Csv)
                } catch {
                    throw [System.Exception] $ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed_derive_tasks))
                }  
            }
        }

        # Call Provider-specific init tasks
        &"$($MachineObj.vars.provider.type)`.invoke.init.tasks" -Machine $MachineObj.name -MachineEnvironment $MachineEnvironment -TaskObjects $TaskObjects -InitTasksFile $InitTasksFile
    }

    end {

    }
}

Function machine.init.list {
    param(
    [Parameter(Mandatory=$False,Position=0)]$MachineName=$Settings.defaults.aiomachine,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",     
    [Alias('TaskFile')]
    [Parameter(Mandatory=$False,Position=3)]$InitTasksFile,
    [switch]$ListVerbose
    )
    if (!$MachineName.name){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else{
        $MachineObj = $MachineName
    }
    $InitTasksFile = "$($Settings.machine.providers.dir)\$($MachineObj.vars.provider.type)\etc\$($Settings.machine.init_file_name)"
    if ($ListVerbose){
        Invoke-InitTask -MachineName $MachineObj -MachineEnvironment $MachineObj.environment -ListTasks -InitTasksFile $InitTasksFile -EnvironmentScope $EnvironmentScope -ListVerbose
    } else {
        Invoke-InitTask -MachineName $MachineObj -MachineEnvironment $MachineObj.environment -ListTasks -InitTasksFile $InitTasksFile -EnvironmentScope $EnvironmentScope
    }
}

Function machine.reinit {
    param(
    [Parameter(Mandatory=$False,Position=0)]$MachineName=$Settings.defaults.aiomachine,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",     
    [Alias('TaskFile')]
    [Parameter(Mandatory=$False,Position=3)]$InitTasksFile
    )
    if (!$MachineName.name){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else{
        $MachineObj = $MachineName
    }
    $InitTasksFile = "$($Settings.machine.providers.dir)\$($MachineObj.vars.provider.type)\etc\$($Settings.machine.init_file_name)"
    Stop-Machine -MachineName $MachineObj -MachineEnvironment $MachineObj.environment -EnvironmentScope $EnvironmentScope -WaitForShutdown

    Invoke-InitTask -MachineName $MachineObj -MachineEnvironment $MachineObj.environment -TaskName ALL -ReInit -InitTasksFile $InitTasksFile -EnvironmentScope $EnvironmentScope
}

Function machine.init.run {
    param(
    [Parameter(Mandatory=$False,Position=0)]$MachineName=$Settings.defaults.aiomachine,
    [Parameter(Mandatory=$True,Position=1)]    
    [Alias('TaskID')]
    $TaskName,
    [Parameter(Mandatory=$False,Position=2)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=3)]
    $EnvironmentScope="Local",     
    [Alias('TaskFile')]
    [Parameter(Mandatory=$False,Position=4)]$InitTasksFile
    )
    if (!$MachineName.name){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else{
        $MachineObj = $MachineName
    }
    $InitTasksFile = "$($Settings.machine.providers.dir)\$($MachineObj.vars.provider.type)\etc\$($Settings.machine.init_file_name)"
    Invoke-InitTask -MachineName $MachineObj -MachineEnvironment $MachineObj.environment -TaskName $TaskName -InitTasksFile $InitTasksFile -EnvironmentScope $EnvironmentScope
}

