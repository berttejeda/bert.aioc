Function Provision-Machine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,Position=3)]
    [Alias('AnsibleInventory','i')]
    $AnsibleInventoryPath,     
    [Parameter(Mandatory=$False,Position=4)]
    [Alias('Controller')]
    $AnsibleController='',
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=5)]
    $EnvironmentScope="Local",
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=6)]
    [Alias('R')]
    $AnsibleRootDir='',
    [parameter(mandatory=$False, Position=7, ValueFromRemainingArguments=$True)]
    $AnsibleArgs,    
    [switch]$UseLocalConnection
    )

    $AnsibleArgsSpec = @{}
    If ($AnsibleArgs) {
        $AnsibleArgs | ForEach-Object {
            if($_ -match '^-') {
                #New parameter
                $lastvar = $_ -replace '^-'
                $AnsibleArgsSpec[$lastvar] = $null
            } else {
                #Value
                $AnsibleArgsSpec[$lastvar] = $_
            }
        }
    }

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.initializing))) -debug

    If ($MachineName.name){
        $MachineObjects = List-Machine $MachineName.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    } Else {
        $MachineObjects = List-Machine $MachineName -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
    }

    ForEach ($MachineObj in $MachineObjects){
        $MachineIsRegistered = $MachineObj.Availability -in @("Created","Ready")
        
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.availability))) -debug

        If (-not $AnsibleInventory){
            If ($IsWindows) {
                $AnsibleInventory = Join-Path $Settings.defaults.InfrastructureFolderName $Settings.defaults.EnvironmentFolderName $MachineObj.environment_name $virtualbox.inventory.defaults.spec
            } else {
                $AnsibleInventory = $MachineObj.InventorySpec
            }
        }

        If ($MachineObj.SelfSame) {
            $UseLocalConnection = $True
        }

        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.ansibleinventory))) -debug

        If ($MachineIsRegistered){
            $MachineIsRunning = $MachineObj.State -in @("Running","Ready", "Pingable")
            If ($MachineIsRunning) {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.provision))) -debug
                switch ($True){
                    ($($AnsibleInventory.Length -gt 0) -and $UseLocalConnection){ 
                        &"$($MachineObj.vars.provider.type)`.provision" -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -AnsibleInventory $AnsibleInventory -AnsibleController $AnsibleController -UseLocalConnection -AnsibleArgs $AnsibleArgsSpec -EnvironmentScope $EnvironmentScope -AnsibleRootDir $AnsibleRootDir
                        break
                    }
                    ($UseLocalConnection){ 
                        &"$($MachineObj.vars.provider.type)`.provision" -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -AnsibleController $AnsibleController -UseLocalConnection -AnsibleArgs $AnsibleArgsSpec -EnvironmentScope $EnvironmentScope -AnsibleRootDir $AnsibleRootDir
                        break
                    }
                    ($AnsibleInventory.Length -gt 0){
                        &"$($MachineObj.vars.provider.type)`.provision" -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -AnsibleInventory $AnsibleInventory -AnsibleController $AnsibleController -AnsibleArgs $AnsibleArgsSpec -EnvironmentScope $EnvironmentScope -AnsibleRootDir $AnsibleRootDir
                        break
                    }
                    default {
                        &"$($MachineObj.vars.provider.type)`.provision" -MachineName $MachineObj -MachineEnvironment $MachineEnvironment -AnsibleController $AnsibleController -AnsibleArgs $AnsibleArgsSpec -EnvironmentScope $EnvironmentScope -AnsibleRootDir $AnsibleRootDir
                    }
                }
            } else {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.not_running))) -warn
            }
        } else {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.no_crr)))
        }    
    }
}

Set-Alias -Name machine.provision -Value Provision-Machine
Set-Alias -Name machine.provision.aio -Value Provision-Machine