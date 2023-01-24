Function Invoke-VirtualMachineInitTasks {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $Machinename=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$True,Position=2)]
    $InitTasksFile,
    [Parameter(Mandatory=$True,Position=3)]
    $TaskObjects
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName
    } else {
        $MachineObj = $MachineName
    }    

    $Global:VMachineState = (List-Machine $MachineObj.name -MachineEnvironment $MachineEnvironment -AsObj).State

    ForEach ($TaskObj in $TaskObjects) {
        
        $_TaskName = $ExecutionContext.InvokeCommand.ExpandString($TaskObj.name)

        if ($TaskObj.task_phase) {
            if ($TaskObj.task_phase -notmatch $VMachineState -and $VMachineState -ne "Unknown" ){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.mismatch)))
                continue
            }
        }

        $wait_for_cli_access = $False
        $wait_for_shared_folders = $False
        $ignore_errors = $False
        $stream_output = $False
        $allowed_exitcodes = @(0)
        $LASTEXITCODE = 0
        $_TaskID = [math]::abs($_TaskName.gethashcode())
        Switch ($True) {
           ([System.Convert]::ToBoolean($TaskObj.wait_for_cli_access))  { $wait_for_cli_access = $True }
           ([System.Convert]::ToBoolean($TaskObj.wait_for_shared_folders))  { $wait_for_shared_folders = $True }
           ([System.Convert]::ToBoolean($TaskObj.ignore_errors))  { $ignore_errors = $True }
           ([System.Convert]::ToBoolean($TaskObj.stream_output))  { $stream_output = $True }
           default { break; }
        }
        if ($TaskObj.allowed_exitcodes)  { 
            $allowed_exitcodes = $TaskObj.allowed_exitcodes 
        }                
        If($TaskObj.delegate_to){
            $delegate_to = $TaskObj.delegate_to
        } Else {
            $delegate_to = "localhost"
        }
        If([System.Convert]::ToBoolean($TaskObj.use_guestcontrol)){
            $use_guestcontrol = $True
        } Else {
            $use_guestcontrol = $False
        }
        If ($TaskObj.when) {
            Switch ($True) {
               ($TaskObj.when -is [array]) { $skip = -not (@($TaskObj.when | Where-Object{$(Invoke-Expression $_) -eq $True}).count -eq $TaskObj.when.count) }
               default { $skip = -not $(Invoke-Expression "$($TaskObj.when)") }
            }
        }

        If ($skip){
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.skipped))) -Warn -Logfiles $MachineObj.logfile
            continue;
        } Else {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.taskname))) -Info -Logfiles $MachineObj.logfile
        }

        Switch ($True) {
           ($wait_for_cli_access -and !$DryRun -and $use_guestcontrol)     { Stat-VirtualBoxMachineCli $MachineObj $MachineObj.environment -UseGuestControl;break }
           ($wait_for_cli_access -and !$DryRun)     { Stat-VirtualBoxMachineCli $MachineObj $MachineObj.environment;break }
           default { break; }
        }  
        Switch ($True) {
           ($wait_for_shared_folders -and !$DryRun -and $use_guestcontrol) { Stat-VirtualBoxSharedFolders $MachineObj $MachineObj.environment -UseGuestControl;break }
           ($wait_for_shared_folders -and !$DryRun) { Stat-VirtualBoxSharedFolders $MachineObj $MachineObj.environment;break }
           default { break; }
        }  

        If($delegate_to -eq "guest") {
            if ($MachineObj.vars.config.os_type -notmatch "Windows"){
                try {
                    If ($TaskObj.vars) {
                        $Vars = ""
                        $TaskObj.vars.psobject.properties | `
                        ForEach-Object { 
                            $Vars += "`$$($_.Name)=$($_.Value)`n"
                        }
                        Try {
                            Invoke-Expression "$Vars"
                        } Catch {
                            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.warn.vars))) -Warn
                            Invoke-Logger $_ -Err
                        }
                    }
                    Invoke-Expression "`$run_cmd = `"$($TaskObj.command)`""
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.run_cmd))) -debug
                    if (!$DryRun) {
                        if ($TaskObj.retries) {
                            # Retry Logic
                            $Stoploop = $false
                            [int]$Retrycount = "0"
                            do {
                                try {
                                    if ($use_guestcontrol) {
                                        Invoke-Expression "$run_cmd"
                                    } else {
                                        SSH-VirtualBoxMachine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -SSHCMD "$run_cmd" -AllowedExitCodes $allowed_exitcodes
                                        $Stoploop = $true
                                    }
                                } catch {
                                    if ($Retrycount -gt $TaskObj.retries){
                                        throw $_
                                    } else {
                                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.retry)))
                                        Start-Sleep -Seconds 5
                                        $Retrycount = $Retrycount + 1
                                    }
                                }
                            }
                            While ($Stoploop -eq $false)                                    
                        } else {
                            if ($use_guestcontrol) {
                                Invoke-Expression "$run_cmd"
                            } else {
                                SSH-VirtualBoxMachine -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -SSHCMD "$run_cmd" -AllowedExitCodes $allowed_exitcodes
                            }
                        }
                    }
                } catch {
                    if ($ignore_errors){
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed))) -Logfiles $MachineObj.logfile -Warn
                        Invoke-Logger $ExecutionContext.InvokeCommand.ExpandString($TaskObj.fail_msg) -Warn -Logfiles $MachineObj.logfile
                        Invoke-Logger $_.Exception.message -Logfiles $MachineObj.logfile -Warn
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.tasksfile))) -Logfiles $MachineObj.logfile -Warn
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.retry_taskid))) -Logfiles $MachineObj.logfile -Color Cyan
                    } else {
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed))) -Logfiles $MachineObj.logfile -Err
                        Invoke-Logger $ExecutionContext.InvokeCommand.ExpandString($TaskObj.fail_msg) -Logfiles $MachineObj.logfile -Err
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.tasksfile))) -Logfiles $MachineObj.logfile -Err
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.retry_taskid))) -Logfiles $MachineObj.logfile -Color Cyan
                        throw $_
                    }
                }
            } else {
                # TODO enable guestcontrol interaction with non-linux hosts
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.unsupported))) -Logfiles $MachineObj.logfile
            }
        } else {
            If($ignore_errors){
                $ErrorActionPreference = 'SilentlyContinue';
                $run_cmd = $TaskObj.command +  ' 2>$NULL'
            } Else {
                $ErrorActionPreference = 'Stop';
                $run_cmd = $TaskObj.command
            }
            try {
                If (!$DryRun){
                    If ($stream_output) {
                        If ($TaskObj.vars) {
                            $Vars = ""
                            $TaskObj.vars.psobject.properties | `
                            ForEach-Object { 
                                $Vars += "`$$($_.Name)=$($_.Value)`n"
                            }
                            Try {
                                Invoke-Expression "$Vars"
                            } Catch {
                                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.vars))) -Warn
                                Invoke-Logger $_ -Err
                            }
                        }
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.run_cmd))) -debug
                        Invoke-Expression "$run_cmd"
                    } Else {
                        If ($TaskObj.vars) {
                            $TaskObj.vars | `
                            Get-Member -MemberType NoteProperty | `
                            ForEach-Object { 
                                $DL = $_.Definition.Length
                                $VarValue = $ExecutionContext.InvokeCommand.ExpandString($_.Definition.split()[1..$DL].Split("=")[1])
                                Set-Variable -Name $_.Name -Value $VarValue                                                                
                            }
                        }                       
                        Invoke-Logger "Run command is '$run_cmd'" -debug
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.run_cmd))) -debug
                        Invoke-Expression "$run_cmd"
                        If ((!$? -or $LASTEXITCODE -ne 0) -and -Not $ignore_errors) {
                          If ($TaskObj.fail_msg){
                            Invoke-Logger $ExecutionContext.InvokeCommand.ExpandString($TaskObj.fail_msg) -Err -Logfiles $MachineObj.logfile
                          } else {
                            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.general)))
                          }
                        }
                    }
                }
            } catch {

                If ($ignore_errors){
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed))) -Logfiles $MachineObj.logfile -Warn
                    Invoke-Logger $ExecutionContext.InvokeCommand.ExpandString($TaskObj.fail_msg) -Warn -Logfiles $MachineObj.logfile
                    Invoke-Logger $_.Exception.message -Logfiles $MachineObj.logfile -Warn
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.tasksfile))) -Logfiles $MachineObj.logfile -Warn
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.retry_taskid))) -Logfiles $MachineObj.logfile -Color Cyan
                } else {
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed))) -Logfiles $MachineObj.logfile -Err
                    Invoke-Logger $ExecutionContext.InvokeCommand.ExpandString($TaskObj.fail_msg) -Logfiles $MachineObj.logfile -Err
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.tasksfile))) -Logfiles $MachineObj.logfile -Err
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.retry_taskid))) -Logfiles $MachineObj.logfile -Color Cyan
                    throw $_
                }
            }
        }
    }   

    Invoke-GarbageCollection
    
}

Function virtualbox.invoke.init.tasks.aio {
    Invoke-VirtualMachineInitTasks -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $virtualbox.defaults.default_environment
}

Set-Alias -Name virtualbox.invoke.init.tasks -Value Invoke-VirtualMachineInitTasks