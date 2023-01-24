Function Import-LocalBox
{
    [CmdletBinding()]             
    param (
    [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)]
    [Alias('Box')] #Accept Pipeline input with objects that feed in a property named VagrantBox or a property named Box
    [string]$VagrantBox,
    [Parameter(Mandatory=$True,Position=1)]$DownloadDirectory,
    [Parameter(Mandatory=$False,Position=2)]$OutFileName="vm.box",
    [switch] $SkipPreDownloadCheck
    )   

    Begin
    {

        Invoke-Command -ScriptBlock $Global:InvocationTrace

        $VagrantBoxObj = Get-Item $VagrantBox
        $VagrantBoxSizeInMB = $VagrantBoxObj.length/1MB
        if (!$(Test-Path $DownloadDirectory)){
            New-Item $DownloadDirectory -ItemType Directory | Out-Null
        }
        $OutFilePath = Join-Path "$DownloadDirectory" "$OutFileName"
    }     

    Process 
    {

        if (!$SkipPreDownloadCheck) {
            # Determine if we have enough space on the $DownloadDirectory's Drive before downloading
            Check-DriveSpace $DownloadDirectory -ObjSize $VagrantBoxSizeInMB
        }
        try {
            Start-BitsTransfer -Source $VagrantBox -Destination $OutFilePath `
            -Description $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.copy.message))) `
            -DisplayName $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.copy.label)))
            Extract-VagrantBox $OutFilePath $DownloadDirectory
        } catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.copy))) -Err
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.options))) -Err
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.vagrantbox))) -Err
            throw $_
        } 

    }
    End 
    {
    }   

}        