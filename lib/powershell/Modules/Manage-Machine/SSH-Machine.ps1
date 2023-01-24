function SSH-Machine() {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
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
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else{
        $MachineObj = $MachineName
    }

    switch ($True){
        ($ListPort -and $quiet){ 
            &"$($MachineObj.vars.provider.type)`.ssh" -MachineName $MachineObj -SSHCMD $SSHCMD -EnvironmentScope $EnvironmentScope -AllowedExitCodes $AllowedExitCodes -ListPort -quiet 
        }
        ($ListPort){ 
            &"$($MachineObj.vars.provider.type)`.ssh" -MachineName $MachineObj -SSHCMD $SSHCMD -EnvironmentScope $EnvironmentScope -AllowedExitCodes $AllowedExitCodes -ListPort
        }
        ($quiet){ 
            &"$($MachineObj.vars.provider.type)`.ssh" -MachineName $MachineObj -SSHCMD $SSHCMD -EnvironmentScope $EnvironmentScope -AllowedExitCodes $AllowedExitCodes -quiet
        }
        default {
            &"$($MachineObj.vars.provider.type)`.ssh" -MachineName $MachineObj -SSHCMD $SSHCMD -EnvironmentScope $EnvironmentScope -AllowedExitCodes $AllowedExitCodes
        }
    }
    
}

Set-Alias -Name machine.ssh -Value SSH-Machine

function machine.ssh.aio {
    param(
    [Parameter(Mandatory=$False,Position=0)]$SSHCMD,
    [Parameter(Mandatory=$False,Position=1)][int[]]$AllowedExitCodes=@(0),
    [switch]$quiet,
    [switch]$ListPort
    )
    switch ($True) {
        ($SSHCMD -ne $NULL){
         SSH-Machine -MachineName $Settings.defaults.aiomachine -MachineEnvironment $Settings.environment.current.path -SSHCMD $SSHCMD -EnvironmentScope $EnvironmentScope
         break
        }
        ($ListPort){
            SSH-Machine -MachineName $Settings.defaults.aiomachine -MachineEnvironment $Settings.environment.current.path -ListPort -EnvironmentScope $EnvironmentScope
            break
        }
        default {
            SSH-Machine -MachineName $Settings.defaults.aiomachine -MachineEnvironment $Settings.environment.current.path -EnvironmentScope $EnvironmentScope
        }
    }

}