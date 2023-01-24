Function Set-MachineEnvironment {
    param(
        [Parameter(Mandatory=$False,Position=0,
        HelpMessage="e.g. environments\myenvironment")]
        [Alias('path')]
        $MachineEnvironment=$Settings.environment.default.path
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if (!$(Test-Path "$MachineEnvironment")){
        try {
            $TargetEnvironment = (Get-Item "$MachineEnvironment").FullName
        } catch {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.not_accessible)))
        }
    } else {
        $TargetEnvironment = "$MachineEnvironment"
    }

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.set)))

    $Settings.environment.current.path = $TargetEnvironment

}

Set-Alias -Name environment.set -Value Set-MachineEnvironment
Set-Alias -Name environment.reset -Value Set-MachineEnvironment