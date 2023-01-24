Function Run-Tests{
    param(
    [Parameter(Mandatory=$False,Position=0)]
    $TestsFile=$Settings.Defaults.tests_file,
    [Parameter(Mandatory=$False,Position=1)]
    $MachineName,
    [Parameter(Mandatory=$False,Position=2)]
    [Alias('env')]
    $MachineEnvironment=$Settings.environment.current.path,
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=3)]
    $EnvironmentScope="Local",  
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=4)]
    $TestName,    
    [switch]$FailOnError
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace
    
    If ($MachineName -and $MachineEnvironment){
        If ($MachineName.name){
            $MachineObj = List-Machine $MachineName.name -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
        } Else {
            $MachineObj = List-Machine $MachineName -MachineEnvironment $MachineEnvironment -EnvironmentScope $EnvironmentScope -AsObject
        }    
    }

    If ($TestName){
        $RunTests = $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Path $TestsFile) | Where-Object {$_.Name -eq $TestName})
    } else {
        $RunTests = $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Path $TestsFile))
    }
    ForEach ($RunTest in $RunTests) {
        $TestName = $ExecutionContext.InvokeCommand.ExpandString($RunTest.name)
        $TestCommand = $RunTest.command
        if (!$TestCommand -and !$TestName){
            Invoke-Expression "Malformed test! - expected 'name' and 'command' keys"
            continue;
        }
        if ([System.Convert]::ToBoolean($RunTest.internal)){
            Invoke-Expression "$TestCommand"
            continue;
        }
        try {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.running_test)))
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.test_command))) -debug
            Invoke-Expression "$TestCommand"
            if (!$RunTest.no_report){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.test_pass))) -info
            }
        } catch {
            if (![System.Convert]::ToBoolean($RunTest.no_report)){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.test_fail))) -err
            }
            if (!$FailOnError){
                Invoke-Logger $_.Exception.Message -Color DarkRed
            }
            Invoke-Logger "Line - $($_.InvocationInfo.Line)" -Color DarkRed
            Invoke-Logger "PositionMessage - $($_.InvocationInfo.PositionMessage)" -Color DarkRed
            Invoke-Logger "Command - $($_.InvocationInfo.MyCommand)" -Color DarkRed
            Invoke-Logger "PSCommandPath - $($_.InvocationInfo.PSCommandPath)" -Color DarkRed
            Invoke-Logger "ScriptName - $($_.InvocationInfo.ScriptName)" -Color DarkRed
            if ($FailOnError){
                throw $_
            }            
        }
    }
}

Set-Alias -Name tests.run -Value Run-Tests