Function Invoke-FileDownload
{
    [CmdletBinding()]             
    param ([Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)][Alias('URL')]$Uri, #Accepts Pipeline input with objects that feed in a property named URL or a property named URI
    [Parameter(Mandatory=$True,Position=1)]$OutputFile,
    [Parameter(Mandatory=$False,Position=2)]$ChunkSize=10KB,
    [Parameter(Mandatory=$False,Position=3)]$Timeout=15,
    [switch] $Force=$True
    )   

    Begin
    {     
        Invoke-Command -ScriptBlock $Global:InvocationTrace
    }     

    Process 
    {
        if (!$Force.IsPresent -and (Test-Path $OutputFile))
        {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.output_exists)))
        }        
       try {
            if (-not $IsWindows){
                &curl --connect-timeout $Timeout -kL "$Uri" -o $OutputFile
            } else {
                &"$APP_DIR\bin\curl.exe" --connect-timeout $Timeout -kL "$Uri" -o $OutputFile
            }
            if ($LASTEXITCODE -ne 0){
                throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.init)))
            }
         } catch [Exception]{
           throw $_
       }
       Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.complete)))
    }
    End 
    {
    }    
}