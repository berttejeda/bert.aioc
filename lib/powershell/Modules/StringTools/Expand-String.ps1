Function Expand-String {
    param(
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=0)]$InputString   
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.input))) -debug

    $ErrorActionPreference = "SilentlyContinue"
    if ($InputString){
        $sl = $InputString.split("`n").length
    } else {
        $sl = 0
    }
    if ($sl -gt 1){
        ForEach ($s in $InputString.split("`n")){
            try{
                $OutputString += $ExecutionContext.InvokeCommand.ExpandString($s)
            } catch {
                $OutputString += '{0}' -f $s
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed))) -debug
            }
        }
        $OutputString = $OutputString -join("`n")
    } else {
        try{
            $OutputString = $ExecutionContext.InvokeCommand.ExpandString($InputString)
        } catch {
            $OutputString = $InputString
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed))) -debug
        }
    }
   return $OutputString
}