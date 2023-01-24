Function Import-CloudBox
{
    [CmdletBinding()]             
    param ([Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)]
    [ValidatePattern("[\w]+\/[\w]+")]
    [Alias('Box')] #Accept Pipeline input with objects that feed in a property named VagrantBox or a property named Box
    [string]$VagrantBox,
    [Parameter(Mandatory=$True,Position=1)]$DownloadDirectory,
    [Parameter(Mandatory=$False,Position=2)]$ChunkSize=10MB,
    [Parameter(Mandatory=$False,Position=3)]$VagrantProvider="virtualbox",
    [switch] $Force,
    [switch] $SkipPreDownloadCheck
    )   

    Begin
    {    
        
        Invoke-Command -ScriptBlock $Global:InvocationTrace

        $BoxInfoUrl = "https://app.vagrantup.com/" + $($VagrantBox -split '/')[0] + "/boxes/" + $($VagrantBox -split '/')[1]
        $VagrantBoxVersionPrep = Invoke-WebRequest -Uri $BoxInfoUrl
        $VersionsInOrderOfRelease = $($VagrantBoxVersionPrep.Links | Where-Object {$_.href -match "versions"}).href | foreach {$($_ -split "/")[-1]}
        $VagrantBoxLatestVersion = $VersionsInOrderOfRelease[0]
        $OutFileName = "vm.box"
        if (!$(Test-Path $DownloadDirectory)){
            New-Item $DownloadDirectory -ItemType Directory | Out-Null
        }          
        $OutFilePath = Join-Path "$DownloadDirectory" "$OutFileName"
    }     

    Process 
    {
        foreach ($version in $VersionsInOrderOfRelease) {
            $VagrantBoxDownloadUrl = "https://vagrantcloud.com/" + $($VagrantBox -split '/')[0] + "/boxes/" + $($VagrantBox -split '/')[1] + "/versions/" + $version + "/providers/" + $VagrantProvider + ".box"
            try {
                # Make sure the Url exists...
                $HTTP_Request = [System.Net.WebRequest]::Create($VagrantBoxDownloadUrl)
                $HTTP_Response = $HTTP_Request.GetResponse()

                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.statuscode)))
            }
            catch {
                continue
            }

            try {
                $bytes = $HTTP_Response.GetResponseHeader("Content-Length")
                $BoxSizeInMB = [Math]::Round($bytes / 1MB)
                $FinalVagrantBoxDownloadUrl = $VagrantBoxDownloadUrl
                $BoxVersion = $version
                break
            }
            catch {
                continue
            }
        }

        if (!$FinalVagrantBoxDownloadUrl) {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.resolve)))
        }

        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.downloadurl)))

        if (!$SkipPreDownloadCheck) {
            # Determine if we have enough space on the $DownloadDirectory's Drive before downloading
            Check-DriveSpace $DownloadDirectory -ObjSize $BoxSizeInMB
        }
        try {
            Invoke-FileDownload -Uri $FinalVagrantBoxDownloadUrl -OutputFile $OutFilePath -ChunkSize $ChunkSize
            Extract-VagrantBox $OutFilePath $DownloadDirectory
        } catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.vhd))) -Err
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.message))) -Err
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.options))) -Err
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.downloadurl))) -Err
            throw $_
        } 

    }
    End 
    {
    }   

}        