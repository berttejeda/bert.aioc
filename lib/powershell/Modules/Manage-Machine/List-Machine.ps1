Function List-Machine {
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $MachineName,
    [Parameter(Mandatory=$False,Position=1,
    HelpMessage="e.g. environments\myenvironment")]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,Position=2)]
    [Alias('group')]
    $MachineGroupSpec,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=3)]
    $EnvironmentScope="Local",    
    [switch]$AsObject,
    [Alias('wide')]
    [switch]$WideOutput
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace
    
    switch ($True){
        ($MachineName.name){ 
            $MachineDefinitions = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName.name -EnvironmentScope $EnvironmentScope 
            $MachineObj = $MachineDefinitions | Where-Object { $_.name -eq $MachineName.name }
            break
        }
        ($MachineName.length -gt 0){
            $MachineDefinitions = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -MachineName $MachineName -EnvironmentScope $EnvironmentScope 
            $MachineObj = $MachineDefinitions | Where-Object { $_.name -eq $MachineName }
            break
        }
        default {
            $MachineDefinitions = Get-MachineDefinitions -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope
        }
    }

    $providers = $($Settings.machine.providers.available.split(',') | Where-Object -FilterScript { $_ -in $MachineDefinitions.vars.provider.type })

    if ($providers){
        $providers = $providers.split(" ")
    } else {
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.no_provider)))
    }

    $MachineStates = @()
    ForEach ($provider in $providers){
        $MachineStates += &"$provider`.list" -MachineDefinitions $MachineDefinitions
    }

    if ($AsObject){
        return $MachineStates
    } elseif($WideOutput) {
        $MachineStates | ForEach-Object { [pscustomobject] $_ } | Format-Table
    } else {
        $MachineStates | ForEach-Object { [pscustomobject] $_ | Select-Object Name,Availability,State,Group,SSHPort,Type } | Format-Table
    }
    
}

Function machine.list.aio {
 List-Machine $Settings.defaults.aio_machine_name
}

Set-Alias -Name machine.list  -Value List-Machine

