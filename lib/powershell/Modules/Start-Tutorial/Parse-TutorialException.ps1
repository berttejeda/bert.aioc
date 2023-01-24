function Parse-TutorialException {
    param(
    [Parameter(Mandatory=$True,Position=0)]$ExceptionMessage,
    [Parameter(Mandatory=$True,Position=1)]$ExceptionObject
    )

    if ($ExceptionMessage){
        Write-Debug $ExceptionMessage
    }
    Write-Debug $ExceptionObject.Exception.Message
    Write-Debug "Line - $($ExceptionObject.InvocationInfo.Line)"
    Write-Debug "PositionMessage - $($ExceptionObject.InvocationInfo.PositionMessage)"
    Write-Debug "Command - $($ExceptionObject.InvocationInfo.MyCommand)"
    Write-Debug "PSCommandPath - $($ExceptionObject.InvocationInfo.PSCommandPath)"
    Write-Debug "ScriptName - $($ExceptionObject.InvocationInfo.ScriptName)"

}