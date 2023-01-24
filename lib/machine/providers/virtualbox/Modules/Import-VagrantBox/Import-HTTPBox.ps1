Function Import-HTTPBox
{
    [CmdletBinding()]             
    param ([Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)]
    [ValidatePattern("^http")]
    [Alias('Box')] #Accept Pipeline input with objects that feed in a property named VagrantBox or a property named Box
    [string]$VagrantBox,
    [Parameter(Mandatory=$True,Position=1)]$DownloadDirectory,
    [Parameter(Mandatory=$False,Position=2)]$ChunkSize=10MB
    )   

    Begin
    {
        
        Invoke-Command -ScriptBlock $Global:InvocationTrace

        $OutFileName = "vm.box" 
        $VagrantBoxName = $($VagrantBox -split '/')[-1].split('.')[0]
        $OutFilePath = Join-Path "$DownloadDirectory" "$OutFileName"

        if (!$(Test-Path $DownloadDirectory)){
            New-Item $DownloadDirectory -ItemType Directory | Out-Null
        } 
        
    }     

    Process 
    {

        try {
            Invoke-FileDownload -Uri $VagrantBox -OutputFile $OutFilePath -ChunkSize $ChunkSize
        } catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.download))) -Err
            throw $_
        }
        try {
            Extract-VagrantBox $OutFilePath $DownloadDirectory
        } catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.vagrantbox))) -Err
            throw $_
        } 

    }
    End 
    {
    }   

}        