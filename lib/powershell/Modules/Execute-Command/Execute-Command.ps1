Function Execute-Command {
    param(
    [Parameter(Mandatory=$True,Position=0)]$commandPath,
    [Parameter(Mandatory=$True,Position=1)]$commandArguments,
    [Parameter(Mandatory=$False,Position=2)]$commandTitle="Execute-Command"
    )   

    Invoke-Command -ScriptBlock $Global:InvocationTrace
    
    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $commandPath
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.Arguments = $commandArguments
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        [pscustomobject]@{
            commandTitle = $commandTitle
            stdout = $p.StandardOutput.ReadToEnd()
            stderr = $p.StandardError.ReadToEnd()
            ExitCode = $p.ExitCode
        }
        $p.WaitForExit()
    } catch {
        throw $_
    }
}