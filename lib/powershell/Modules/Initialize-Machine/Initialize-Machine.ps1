Function Initialize-Machine {
  [CmdletBinding()]             
  param ([Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)]
  [Alias('Name')]
  $MachineName,
  [Parameter(Mandatory=$False,Position=1)]
  [Alias('env')]
  $MachineEnvironment=$Settings.environment.current.path,
  [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
  $EnvironmentScope="Local",  
  [Parameter(Mandatory=$True,Position=3)]$MachineSettings,
  [Parameter(Mandatory=$False,Position=4)]$InitFileOverrides,
  [switch]$Create,
  [switch]$Start,
  [switch]$Stop,
  [switch]$DryRun
  )
  Begin
  {   

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if ($(-not $MachineName.name)){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else {
        $MachineObj = $MachineName
    }    
    $MachineProviderTaskFiles = @(
      "$($Settings.machine.providers.dir)\$($MachineObj.vars.provider.type)\etc\$($Settings.machine.init_file_name)",
      "$($MachineObj.environment)\etc\$($Settings.machine.init_file_name)"
      )
  }
  Process 
  {
      Switch ($True) {
         ($Stop)  { Stop-Machine -MachineName $MachineName; break }
         ($Start -and $Create)  { 
              $MachineProviderTaskFileFound = $False
              ForEach ($MachineProviderTaskFile in $MachineProviderTaskFiles) {
                if (Test-Path $MachineProviderTaskFile) {
                  Configure-Machine -MachineName $MachineName -InitTasksFile "$MachineProviderTaskFile" -EnvironmentScope $EnvironmentScope -DryRun $DryRun
                  $MachineProviderTaskFileFound = $True
                }
              }
              if (-Not $MachineProviderTaskFileFound){
                throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.no_init_found)))
              }
              break
         }
         ($Start)  { Start-Machine -MachineName $MachineName -EnvironmentScope $EnvironmentScope; break }
         default {
          throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.no_state)))
        }
                
      } 
  }
  End 
  {
  }
}