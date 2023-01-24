Function List-BareMetalMachine {
    param(
    [Parameter(Mandatory=$True,Position=0)]
    $MachineDefinitions
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    $ErrorActionPreference = 'SilentlyContinue'
    $MachineObjList = @()
    $MyProviderType = 'baremetal'


    ForEach ($MachineObj in $MachineDefinitions) {

         if ($MachineObj.vars.config.ssh.port) {
           $MachineSSHPort = $MachineObj.vars.config.ssh.port
         } else {
           $MachineSSHPort = $BareMetal.ssh.port
         }

         $MachineProviderType = $MachineObj.vars.provider.type
         Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.provider.type))) -debug
         if (!$MachineProviderType){
             Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.provider.missing))) -debug
             continue
         } else {
            if ($MachineProviderType -ne $MyProviderType){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.provider.mismatch))) -debug
                continue
            }
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.testing.port))) -debug
            if ($MachineObj.SelfSame){
                $MachineIsPingable = $True
            } else {
                $MachineIsPingable = Test-NetPort -ComputerName $MachineObj.name -Port $MachineSSHPort
            }
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.status))) -debug
            if ($MachineIsPingable){
                $MachineAvailability = "Ready"
                $MachineState = "Pingable"
            } else {
                $MachineAvailability = "Not Pingable"
                $MachineState = "Unknown"
            }             
         }
         $MachineObj.add("Name",$MachineObj.Name)
         $MachineObj.add("Availability",$MachineAvailability)
         $MachineObj.add("State",$MachineState)
         $MachineObj.add("Group",$MachineObj.group)
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

Set-Alias -Name baremetal.list -Value List-BareMetalMachine