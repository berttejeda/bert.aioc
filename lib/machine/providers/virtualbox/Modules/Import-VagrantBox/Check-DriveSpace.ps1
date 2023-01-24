Function Check-DriveSpace
{
    [CmdletBinding()]             
    param ([Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)]
    [ValidatePattern("^[\w]:")]
    [Alias('Folder')]
    [string]$Directory,
    [string]$ObjSize
    )   

    Begin
    {    

        Invoke-Command -ScriptBlock $Global:InvocationTrace
         
        if ([bool]$(Get-Item $Directory).LinkType) {
            $DownloadDirLogicalDriveLetter = $(Get-Item $Directory).Target[0].Substring(0,1)
        }
        else {
            $DownloadDirLogicalDriveLetter = $Directory.Substring(0,1)
        }        
    }     

    Process 
    {
        $DownloadDirDriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object {$_.Name -eq $($DownloadDirLogicalDriveLetter + ':\')}
        
        if ($([Math]::Round($DownloadDirDriveInfo.AvailableFreeSpace / 1MB)-2000) -gt $BoxSizeInMB) {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.space)))
        } else {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.space)))
        }
    }

    end {

    }

}