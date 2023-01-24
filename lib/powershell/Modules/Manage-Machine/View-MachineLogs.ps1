Function View-MachineLogs {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName=$Settings.defaults.aio_machine_name,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,Position=2)]$Filter,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=3)]
    $EnvironmentScope="Local"   
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if (!$MachineName.name){
        $MachineObj = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope
    } else{
        $MachineObj = $MachineName
    }

    if (Test-Path $MachineObj.logfile){
        if ($Filter) {
            try {
                Get-Content $MachineObj.logfile | Where-Object {$_ -match "$Filter" } | Out-Host -paging
            } catch {
            }
        } else {
            try {
                Get-Content $MachineObj.logfile | Out-Host -paging
            } catch {
            }
        }
    } else {
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.logfile_dne))) -warn
    }

}

Set-Alias -Name machine.logs  -Value View-MachineLogs 
Set-Alias -Name machine.logs.aio  -Value View-MachineLogs