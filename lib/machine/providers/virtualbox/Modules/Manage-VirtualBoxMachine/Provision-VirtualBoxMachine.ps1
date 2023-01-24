Function Provision-VirtualBoxMachine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    [Alias('Machine')]
    $MachineName=$virtualbox.defaults.aio_vm_name,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,    
    [Parameter(Mandatory=$False,Position=2)]
    [Alias('AnsibleInventory','i')]
    $AnsibleInventoryPath,    
    [Parameter(Mandatory=$False,Position=3)]
    [Alias('Controller')]
    $AnsibleController,
    [parameter(mandatory=$True, position=4)]
    $AnsibleArgs,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=5)]
    $EnvironmentScope="Local",      
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=6)]
    [Alias('U')]
    $LocalAnsibleUser=$virtualbox.provisioners.ansible.LocalAnsibleUser,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=7)]
    [Alias('R')]
    $AnsibleRootDir,    
    [Alias('local')]
    [switch]$UseLocalConnection,
    [switch]$UseGuestControl
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.scope))) -debug
   
    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName
    } else {
        $MachineObj = $MachineName
    }

    if (-not $virtualbox.environment.VboxManageAvailable -and -not $MachineObj.SelfSame) {
        throw [System.Exception] $(Expand-String $virtualbox.i18n.enUS.General.errors.vbox_cli.not_found)
    }    

    if ($AnsibleController -and $IsWindows){
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ansible.controller))) -debug
        $TargetMachine = $AnsibleController
    } else {
        $TargetMachine = $MachineObj
    }

    if ($AnsibleInventoryPath) {
        if (Test-Path $AnsibleInventoryPath) {
            if ($IsWindows) {
                $AnsibleInventoryObj = Get-Item $AnsibleInventoryPath
                $AnsibleInventorySpec = "$(Get-SharedFolderItemPosixPath -MachineObj $MachineObj -FileObj $AnsibleInventoryObj)"
            } else {
                $AnsibleInventorySpec = $AnsibleInventoryPath
            }
        } else {
            $AnsibleInventorySpec = "$($MachineObj.name),"
        }
    } else {
        $AnsibleInventorySpec = "$($MachineObj.name),"
    }

    if ($UseAnsibleTaskRunner){
        $AnsibleInventoryArgs = "---inventory $AnsibleInventorySpec"
    } else {
        $AnsibleInventoryArgs = "-i $AnsibleInventorySpec"
    }

    if ($UseLocalConnection){
        $AnsibleConnectionArgs = "-c local"
    }

    if ($AnsibleRootDir.Length -gt 0){
        $ANSIBLEROOTARGS = "cd $AnsibleRootDir"
    } else {
        $ANSIBLEROOTARGS = "cd $($MachineObj.program_dir)"
    }

    $AnsibleVaultFileLocalPath = $MachineObj.environment + '\' + $virtualbox.provisioners.ansible.VaultFileName
    $AnsibleVaultFilePath = $MachineObj.environment_posix_path + '/' + $virtualbox.provisioners.ansible.VaultFileName

    if (Test-Path $AnsibleVaultFileLocalPath){
        $AnsibleVaultArgs = "--vault-password-file $AnsibleVaultFilePath"
    } else {
        $AnsibleVaultArgs = ""
    }

    $AnsibleArgs.Keys | ForEach-Object {
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ansible.args))) -debug
    }

    ForEach ($var in $($AnsibleArgs.Keys | Where-Object {$_ -ne 'playbook'})){
        $AnsibleVars += "-e $var=$($AnsibleArgs[$var]) "
    } 

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ansible.vars))) -debug

    if ($AnsibleArgs.playbook){
        $AnsiblePlaybook = $AnsibleArgs.playbook
    } else {
        $AnsiblePlaybook = $MachineObj.definition_posix_path
    }

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ansible.playbook))) -debug

    switch ($True) {
        ($UseAnsibleTaskRunner) {
            $SSHCMD = "$ANSIBLEROOTARGS;/usr/bin/env tasks -f $AnsiblePlaybook run $AnsibleInventoryArgs ---raw $AnsibleVaultArgs $AnsibleConnectionArgs $AnsibleVars"
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.sshcmd))) -debug
            SSH-Machine -MachineName $TargetMachine -MachineEnvironment $MachineEnvironment -SSHCMD "$SSHCMD" -EnvironmentScope $EnvironmentScope
            break
        }
        ($UseGuestControl) {
            &$virtualbox.defaults.VboxManagePath guestcontrol $TargetMachine --username root run -- $ANSIBLEROOTARGS;/usr/bin/env ansible-playbook $AnsibleVaultArgs $AnsibleInventoryArgs $AnsibleConnectionArgs $AnsibleVars $AnsiblePlaybook
            break
        }
        default {
            if ($IsWindows) {
                $SSHCMD = "sudo su - $LocalAnsibleUser -c '$ANSIBLEROOTARGS && /usr/bin/env ansible-playbook $AnsibleVaultArgs $AnsibleInventoryArgs $AnsibleConnectionArgs $AnsibleVars $AnsiblePlaybook'"
            } else {
                $SSHCMD = "$ANSIBLEROOTARGS && /usr/bin/env ansible-playbook $AnsibleVaultArgs $AnsibleInventoryArgs $AnsibleConnectionArgs $AnsibleVars $AnsiblePlaybook"
            }
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.sshcmd))) -debug
            SSH-Machine -MachineName $TargetMachine -MachineEnvironment $MachineEnvironment -SSHCMD "$SSHCMD" -EnvironmentScope $EnvironmentScope
        }
    }

    If ($LASTEXITCODE -ne 0) {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed)))
    }
}

Function virtualbox.provision.aio {
    Provision-VirtualBoxMachine -MachineName $virtualbox.defaults.aio_vm_name -MachineEnvironment $virtualbox.defaults.default_environment
}

Set-Alias -Name virtualbox.provision -Value Provision-VirtualBoxMachine