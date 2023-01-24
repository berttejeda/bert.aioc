function SSH-VirtualBoxMachine() {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,Position=2)]$SSHCMD,
    [Parameter(Mandatory=$False,Position=3)][int[]]$AllowedExitCodes=@(0),
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=4)]
    $EnvironmentScope="Local",      
    [switch]$quiet,
    [switch]$ListPort
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    $DebugParameterIsPresent = $PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent
    $GlobalDebugIsOn = $Global:DebugPreference -eq "Continue"

    If ($MachineName.name){
        $MachineObj = List-Machine $MachineName.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    } Else {
        $MachineObj = List-Machine $MachineName -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    }

    if (-not $virtualbox.environment.VboxManageAvailable -and -not $MachineObj.SelfSame) {
        throw [System.Exception] $(Expand-String $virtualbox.i18n.enUS.General.errors.vbox_cli.not_found)
    }

    $MachineIsRunning = $MachineObj.State -in @("Running","Ready")

    If ($MachineIsRunning) {
        If ($BuildTimeMachineSSHPort){
            $MachineSSHPort = $BuildTimeMachineSSHPort
        } Else {
            $MachineSSHMetadata = &$virtualbox.defaults.VboxManagePath showvminfo $MachineObj.name --machinereadable | Select-String 'ssh'
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.metadata))) -debug
            if ($MachineSSHMetadata) {
                $MachineSSHPort = ($($MachineSSHMetadata | Select-String 'ssh') -split(','))[3]
            } else {
                throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.ssh.port)))
            }            
        }
        If ($ListPort){
            return $MachineSSHPort
        }
        if ($MachineObj.vars.config.ssh.username){
            $ssh_username = $MachineObj.vars.config.ssh.username
        } else {
            $ssh_username = $virtualbox.ssh.username
        } 
        if ($GlobalDebugIsOn) {
            $SSHLogLevel = "debug"
        } else {
            $SSHLogLevel = "quiet"
        }
        if ($MachineObj.vars.config.ssh.private_key) {
            $ssh_private_key = "$APP_DIR\etc\ssh_keys\$($MachineObj.vars.config.ssh.private_key)"
            try {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.login))) -debug
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.command))) -debug
                &"$APP_DIR\bin\ssh.exe" -i $ssh_private_key -o "LogLevel=$SSHLogLevel" -o "UserKnownHostsFile=NUL" -o "StrictHostKeyChecking=no" $ssh_username@localhost -p $MachineSSHPort ">/dev/null"
                if ($AllowedExitCodes -notcontains $LASTEXITCODE)
                {
                    throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.ssh.execution)))
                }
                $Successful = $True
            } catch {
                Invoke-Logger $_.Exception.Message -Debug
                $Successful = $False
            }   
            if ($Successful){
                $ssh_private_key = $ssh_private_key
            } else {
                $ssh_private_key = $virtualbox.ssh.private_key
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.privatekey))) -debug
            }
        } else {
            $ssh_private_key = $virtualbox.ssh.private_key
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.privatekey))) -debug
        }
        if (!$SSHCMD -or $Debug) {
            &"$APP_DIR\bin\ssh.exe" -i $ssh_private_key -o LogLevel=$SSHLogLevel -o "UserKnownHostsFile NUL" -o StrictHostKeyChecking=no "$ssh_username@localhost" -p $MachineSSHPort "$SSHCMD"
        } else {

            try {
&bin\ssh.exe -i $ssh_private_key -o "LogLevel=$SSHLogLevel "-o "UserKnownHostsFile NUL" -o "StrictHostKeyChecking=no" $ssh_username@localhost -p $MachineSSHPort @"
$SSHCMD
"@ | ForEach-Object -Process `
                {
                    if ($_ -is [System.Management.Automation.ErrorRecord])
                    {
                        if (!$quiet -and $_) {
                            Invoke-Logger "$_" -Err -Logfiles $MachineObj.logfile
                        }                                         
                    }
                    else
                    {
                        if (!$quiet -and $_) {
                            Invoke-Logger "$_" -Logfiles $MachineObj.logfile
                        }                        
                    }
                }
                if ($AllowedExitCodes -notcontains $LASTEXITCODE)
                {
                    throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.ssh.execution)))
                }            
            } catch { 
                throw $_
            }
        }
        
    } Else {
        if ($ListPort) {
            return "n/a"
        }        
        if (!$quiet) {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.notrunning)))
        }        
    }

}

Set-Alias -Name virtualbox.ssh -Value SSH-VirtualBoxMachine

function virtualbox.ssh.aio {
    param(
    [Parameter(Mandatory=$False,Position=0)]$SSHCMD,
    [Parameter(Mandatory=$False,Position=1)][int[]]$AllowedExitCodes=@(0),
    [switch]$quiet,
    [switch]$ListPort
    )
    switch ($True) {
        ($SSHCMD){
         SSH-VirtualBoxMachine -MachineName $Settings.defaults.aiomachine -MachineEnvironment $Settings.environment.current.path -SSHCMD $SSHCMD
         break
        }
        ($ListPort){
            SSH-VirtualBoxMachine -MachineName $Settings.defaults.aiomachine -MachineEnvironment $Settings.environment.current.path -ListPort
            break
        }
        default {
            SSH-VirtualBoxMachine -MachineName $Settings.defaults.aiomachine -MachineEnvironment $Settings.environment.current.path
        }
    }

}