Function Provision-BareMetalMachine {
    param(
    [Parameter(Mandatory=$True,Position=0)]
    [Alias('Machine')]
    $MachineName,
    [Parameter(Mandatory=$False,Position=1)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,    
    [Parameter(Mandatory=$False,Position=2)]
    [Alias('AnsibleInventory','i')]
    $AnsibleInventoryPath,    
    [Parameter(Mandatory=$True,Position=3)]
    [Alias('Controller')]
    $AnsibleController,
    [parameter(mandatory=$True, position=4)]
    $AnsibleArgs,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=5)]
    $EnvironmentScope="Local", 
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=6)]
    [Alias('U')]
    $LocalAnsibleUser=$baremetal.provisioners.ansible.LocalAnsibleUser,    
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=7)]
    [Alias('R')]
    $AnsibleRootDir,
    [Alias('local')]
    [switch]$UseLocalConnection
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.scope))) -debug

    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $Machine
    } else {
        $MachineObj = $MachineName
    }

    if ($IsWindows -and -not $MachineObj.SelfSame) {
        if ($AnsibleController.Length -gt 0){
            $AnsibleControllerName = $AnsibleController
        } else {
            $AnsibleControllerName = "ansible.$($MachineObj.environment_name)"
        }

        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.specs))) -debug
        
        $AnsibleControllerObj = List-Machine $AnsibleControllerName -MachineEnvironment $MachineEnvironment -EnvironmentScope All -AsObject

        if (-not $($AnsibleControllerObj.State -in @("Running","Ready"))){
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed)))
        }

        $AnsibleInventorySpec = "$($AnsibleControllerObj.environments_posix_path)/$($MachineObj.InventorySpec)"
    }
    

    if ($AnsibleArgs.inventory) {
        $AnsibleInventorySpec = $AnsibleArgs.inventory
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
        $ANSIBLEROOTARGS = ">/dev/null"
    }

    $AnsibleVaultFileLocalPath = Join-Path -Path $MachineObj.environment -ChildPath $baremetal.provisioners.ansible.VaultFileName
    $AnsibleVaultFilePath = "$($Settings.defaults.InfrastructureFolderName)/$($Settings.defaults.EnvironmentFolderName)/$($MachineObj.environment_name)/$($baremetal.provisioners.ansible.VaultFileName)"
    
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

    try {
        $SSHCMD = "sudo su - $LocalAnsibleUser -c '$ANSIBLEROOTARGS && ENVIRONMENT=$($MachineObj.environment_name) /usr/bin/env ansible-playbook $AnsibleVaultArgs $AnsibleInventoryArgs $AnsibleConnectionArgs $AnsibleVars $AnsiblePlaybook'"
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.sshcmd))) -debug
        SSH-Machine -MachineName $AnsibleControllerObj -MachineEnvironment $AnsibleControllerObj.environment_name -EnvironmentScope All -SSHCMD $SSHCMD
    } catch {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.provisionment)))
    }
    
}

Function BareMetal.provision.aio {
    Provision-BareMetalMachine -Machine $BareMetal.defaults.aio_vm_name -MachineEnvironment $BareMetal.defaults.default_environment -AnsiblePlaybookPath $AnsiblePlaybookPath
}

Set-Alias -Name BareMetal.provision -Value Provision-BareMetalMachine