Function List-VirtualBoxMachine {
    param(
    [Parameter(Mandatory=$True,Position=0)]
    $MachineDefinitions
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if ($virtualbox.environment.VboxManageAvailable) {
        $MachineStates = Get-VirtualBoxMachineStates
        $RegisteredVMs = $(&$virtualbox.defaults.VboxManagePath list vms)
    } else {
        $MachineStates = @{}
        $RegisteredVMs = @{}
    }
    
    $MachineObjList = @()
    $MyProviderType = 'virtualbox'

    ForEach ($MachineObj in $MachineDefinitions) {
    
         $MachineProviderType = $MachineObj.vars.provider.type
         Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.provider.type))) -debug
         if (!$MachineProviderType){
             Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.provider.missing))) -Err
             continue
         } else {
            if ($MachineProviderType -ne $MyProviderType){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.provider.mismatch))) -debug
                continue
            }
            $MachineIsRegistered = $RegisteredVMs | ForEach-Object {$_ -match $MachineObj.name} | Where-Object {$_}
            if ($MachineIsRegistered){
                $MachineAvailability = "Created"
                $MachineState = ($MachineStates | Where-Object { $_.Name -eq $MachineObj.name}).State
                If (!$MachineSSHPort){
                    if ($virtualbox.environment.VboxManageAvailable) {
                        $MachineSSHMetadata = &$virtualbox.defaults.VboxManagePath showvminfo $MachineObj.name --machinereadable | Select-String 'ssh'
                    }
                    if ($MachineSSHMetadata) {
                        $MachineSSHPort = ($($MachineSSHMetadata | Select-String 'ssh') -split(','))[3]
                    } else {
                        $MachineSSHPort = "n/a"
                    }
                } 
            } elseif ($MachineObj.SelfSame) {
                $MachineAvailability = "Created"
                $MachineState = "Running"
                $MachineSSHPort = "22"
            } else {
                $MachineAvailability = "Not Created"
                $MachineState = "Unknown"
                $MachineSSHPort = "n/a"
            }             
         }
         # $MachineObj.add("Name",$MachineObj.Name)
         $MachineObj.add("Availability",$MachineAvailability)
         $MachineObj.add("State",$MachineState)
         # $MachineObj.add("Group",$MachineObj.group)
         $MachineObj.add("SSHPort",$MachineSSHPort)
         $MachineObj.add("Type",$MachineObj.vars.provider.type)         
         $MachineObjList += $MachineObj
         # Cleanup Variables
         $MachineSSHPort = ""
         $MachineAvailability = ""         
         $MachineState = ""         
     }    

    return $MachineObjList
}

Function virtualbox.list.aio {
    param(
    [Parameter(Mandatory=$False,Position=0)]$MachineName,
    [Parameter(Mandatory=$False,Position=1,HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$virtualbox.defaults.default_environment,
    [Parameter(Mandatory=$False,Position=2)]
    [Alias('group')]
    $MachineGroupSpec,
    [switch]$AsObject
    )

    if (Test-Path $MachineEnvironment) {
        $MachineEnvironment = (Get-Item $MachineEnvironment).Basename
    }     

    if ($MachineName){
        $MachineDefinitions = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName
    } else {
        $MachineDefinitions = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment
    }  

    List-VirtualBoxMachine -MachineDefinitions $MachineDefinitions
}

 Set-Alias -Name virtualbox.list -Value List-VirtualBoxMachine