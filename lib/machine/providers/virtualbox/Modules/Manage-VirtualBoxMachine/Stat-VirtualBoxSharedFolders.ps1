Function Stat-VirtualBoxSharedFolders {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",
    [switch]$UseGuestControl
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if (-not $virtualbox.environment.VboxManageAvailable) {
        throw [System.Exception] $(Expand-String $virtualbox.i18n.enUS.General.errors.vbox_cli.not_found)
    }
    
    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else {
        $MachineObj = $MachineName
    }  

    $progressBar = ' ','#'
    if ($MachineObj.vars.config.connection_timeout){
        $timeout = New-TimeSpan -Seconds $MachineObj.vars.config.connection_timeout
    } else {
        $timeout = New-TimeSpan -Seconds $virtualbox.defaults.timeouts.connect
    }  
    $endTime = (Get-Date).Add($timeout)        
    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.guestcontrol))) -debug
    if (!$UseGuestControl){

        if ($MachineObj.vars.config.ssh.username){
            $ssh_username = $MachineObj.vars.config.ssh.username
        } else {
            $ssh_username = $Settings.machine.ssh.username
        }
        # Try accessing the default program directory twice for good measure
        $HeartBeatCMD = "/usr/bin/test -d $($virtualbox.defaults.program_dir) || /usr/bin/test -d $($virtualbox.defaults.program_dir)"
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.heartbeat))) -debug
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.wait.available))) -NoNewLine
        Do {
            try {
                SSH-Machine -MachineName $MachineObj -MachineEnvironment $MachineObj.environment -SSHCMD "$HeartBeatCMD" -quiet
                $Successful = $True
            } catch {
                $Successful = $False
            }
            ForEach ($c in $progressBar){Write-Host -NoNewLine $c`b;Start-Sleep -MilliSeconds 100}
        } Until($Successful -or ((Get-Date) -gt $endTime))
        Write-Host `r
    } else {
        switch ($True){
         ($MachineObj.vars.config.ssh.username -ne $NULL) { $vboxusername = $MachineObj.vars.config.ssh.username }
         ($MachineObj.vars.config.ssh.password -ne $NULL) { $vboxpassword = $MachineObj.vars.config.ssh.password }
         default {break;}
        }
        switch ($True){
            ($vboxusername -and $vboxpassword) {
                $HeartBeatCMD = @("guestcontrol", $MachineObj.Name, "--username", $vboxusername, "--password", $vboxpassword, "run", "--", "/usr/bin/test", '-d', $virtualbox.defaults.program_dir)
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.heartbeat))) -debug
                break
            }
            ($vboxusername) {
                $HeartBeatCMD = @("guestcontrol", $MachineObj.Name, "--username", $vboxusername, "run", "--", "/usr/bin/test", '-d', $virtualbox.defaults.program_dir)
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.heartbeat))) -debug
                break
            }
            default {
                $HeartBeatCMD = @("guestcontrol", $MachineObj.Name, "--username", "root", "run", "--", "/usr/bin/test", '-d', $virtualbox.defaults.program_dir)
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.heartbeat))) -debug
            }
        }
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.heartbeat))) -debug
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.wait.available))) -NoNewLine
        Do {
            $pinfo.FileName = "$($virtualbox.defaults.VboxManagePath)"
            $pinfo.RedirectStandardError = $true
            $pinfo.RedirectStandardOutput = $true
            $pinfo.UseShellExecute = $false
            $pinfo.Arguments = $HeartBeatCMD
            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $pinfo
            $p.Start() | Out-Null      
            ForEach ($c in $progressBar){Write-Host -NoNewLine $c`b;Start-Sleep -MilliSeconds 100}
        } Until($p.ExitCode -eq 0 -or ((Get-Date) -gt $endTime))
        Write-Host `r
    }
}

Function machine.stat.sharedfolders.aio {
    param(
    [switch]$UseGuestControl
    ) 
    Switch ($True) {
       ($UseGuestControl)  { Stat-VirtualBoxSharedFolders -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $virtualbox.defaults.default_environment -UseGuestControl $True;break }
       default { Stat-VirtualBoxSharedFolders -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $virtualbox.defaults.default_environment }
    }    
    
}

Set-Alias -Name virtualbox.stat.sharedfolders -Value Stat-VirtualBoxSharedFolders