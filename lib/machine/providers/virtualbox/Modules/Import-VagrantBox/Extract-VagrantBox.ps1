Function Extract-VagrantBox
{
    [CmdletBinding()]             
    param ([Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)]
    [Alias('Box')]
    [string]$TargetBox,
    [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=1)]
    [string]$OutputPath
    )   

    Begin
    {
        Invoke-Command -ScriptBlock $Global:InvocationTrace
    }     

    Process 
    {
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.extracting))) -Color Magenta
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.targetbox))) -debug
        $ProcessArgs = @("e","`"$TargetBox`"","-aoa","-o`"$OutputPath`"")
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.command))) -debug
        $VagrantfilePath = Join-Path "$OutputPath" "Vagrantfile"
        $Process = Start-Process -FilePath "bin\7z.exe" -ArgumentList $ProcessArgs -NoNewWindow -PassThru -RedirectStandardOutput ".\NUL" -Wait
        if ($Process.ExitCode -eq 0) {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.success)))
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.remove.box)))
            Remove-Item -Path "$TargetBox" -ErrorAction SilentlyContinue | Out-Null
            if (-not $(Test-Path "$VagrantfilePath")){
                $OutIntermediateFilePath = (Get-Item -Path "$OutputPath\*" | ?{ $_.Name -notmatch "vmdk|ovf"}).FullName
                if (Test-Path $OutIntermediateFilePath){
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.intermediate))) -Color Magenta
                    $ProcessArgs = @("e","`"$OutIntermediateFilePath`"","-aoa","-o`"$OutputPath`"","-r","*.vmdk")
                    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.command))) -debug
                    $Process = Start-Process -FilePath "bin\7z.exe" -ArgumentList  $ProcessArgs -NoNewWindow -PassThru -RedirectStandardOutput ".\NUL" -Wait
                    if ($Process.ExitCode -eq 0) {
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.remove.intermediate)))
                        Remove-Item -Path "$OutIntermediateFilePath" -ErrorAction SilentlyContinue | Out-Null
                    }
                }               
            }
        } else {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.extracting)))
        }
    }

    end {

    }

}

