Function Stat-BareMetalMachineCli {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$baremetal.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
    $EnvironmentScope="Local",     
    [switch]$UntilNotAvailable
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else {
        $MachineObj = $MachineName
    }    

    $progressBar = ' ','#'
    if ($MachineObj.vars.config.connection_timeout){
        $timeout = New-TimeSpan -Seconds $MachineObj.vars.config.connection_timeout
    } else {
        $timeout = New-TimeSpan -Seconds $baremetal.defaults.timeouts.connect
    }  
    $endTime = (Get-Date).Add($timeout)

    If ($UntilNotAvailable){
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.wait.unavailable))) -NoNewLine
    } else {
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.wait.available))) -NoNewLine
    }    
    if ($MachineObj.vars.config.ssh.username){
        $ssh_username = $MachineObj.vars.config.ssh.username
    } else {
        $ssh_username = $Settings.machine.ssh.username
    }
    # Try accessing the macine terminal twice for good measure
    $HeartBeatCMD = "/bin/env true || /bin/env true"
    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.heartbeat))) -debug
    Do {
        try {
            SSH-Machine -MachineName $MachineObj -MachineEnvironment $MachineObj.environment -SSHCMD "$HeartBeatCMD" -quiet
            $Successful = $True
        } catch {
            $Successful = $False
        }
        ForEach ($c in $progressBar){Write-Host -NoNewLine $c`b;Start-Sleep -MilliSeconds 100}
    } Until($(if ($UntilNotAvailable){$Successful -eq $False}else{$Successful -eq $True}) -or ((Get-Date) -gt $endTime))
    Write-Host `r
}

Function baremetal.stat.cli.aio {
    param(
    [switch]$UseGuestControl
    ) 
    Switch ($True) {
       ($UseGuestControl)  { Stat-BareMetalMachineCli -MachineName $baremetal.defaults.aio_vm_name -MachineEnvironment $baremetal.defaults.default_environment -UseGuestControl $True;break }
       default { Stat-BareMetalMachineCli -MachineName $baremetal.defaults.aio_vm_name -MachineEnvironment $baremetal.defaults.default_environment }
    }    
    
}

Set-Alias -Name baremetal.stat.cli -Value Stat-BareMetalMachineCli