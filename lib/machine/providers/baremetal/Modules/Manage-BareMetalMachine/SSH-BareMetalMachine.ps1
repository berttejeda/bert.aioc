function SSH-BareMetalMachine() {
    param(
    [Parameter(Mandatory=$True,Position=0)]
    $MachineName,
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

    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName
    } else{
        $MachineObj = $MachineName
    }

    $MachineStateData = List-Machine $MachineObj.name -MachineEnvironment $MachineEnvironment -AsObj
    $MachineIsRunning = $($MachineStateData.State -in @("Running","Ready","Pingable"))
    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.port))) -debug
    If ($MachineIsRunning) {
        If ($ListPort){
            return $MachineStateData.SSHPort
        }
        if ($MachineObj.vars.config.ssh.username){
            $ssh_username = $MachineObj.vars.config.ssh.username
        } else {
            $ssh_username = $baremetal.ssh.username
        }
        if ($GlobalDebugIsOn) {
            $SSHLogLevel = "debug"
        } else {
            $SSHLogLevel = "quiet"
        }
        if ($MachineObj.vars.config.ssh.private_key) {
            $ssh_private_key = $MachineObj.vars.config.ssh.private_key
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
            if (!$Successful){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.privatekey))) -debug
                if ($baremetal.ssh.keys.private){
                    $ssh_private_key = $baremetal.ssh.keys.private
                } else {
                    throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.ssh.privatekey)))
                }
            }
        } else {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.privatekeyms))) -debug
            if ($baremetal.ssh.keys.private){
                $ssh_private_key = $baremetal.ssh.keys.private
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ssh.privatekey))) -debug
            } else {
                throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.ssh.privatekey)))
            }
        }
        if (!$SSHCMD -or $Debug) {
            &"$APP_DIR\bin\ssh.exe" -i $ssh_private_key -o LogLevel=$SSHLogLevel -o "UserKnownHostsFile NUL" -o StrictHostKeyChecking=no "$ssh_username@$($MachineObj.name)" -p $MachineStateData.SSHPort "$SSHCMD"
        } else {

            try {
&bin\ssh.exe -i $ssh_private_key -o "LogLevel=$SSHLogLevel "-o "UserKnownHostsFile NUL" -o "StrictHostKeyChecking=no" "$ssh_username@$($MachineObj.name)" -p $MachineStateData.SSHPort @"
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

Set-Alias -Name baremetal.ssh -Value SSH-BareMetalMachine