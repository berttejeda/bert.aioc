$Global:InvocationTrace = [scriptblock]::Create(
@'
    if ($MyInvocation.CommandOrigin -eq "Runspace") {
        $Caller = "Terminal"
    } else {
        $Caller = $($MyInvocation.PSCommandPath)
    }
    if (!$Caller) { $Caller = "n/a" }
    Invoke-Logger "Calling $($MyInvocation.MyCommand), caller: $Caller" -debug
'@
)