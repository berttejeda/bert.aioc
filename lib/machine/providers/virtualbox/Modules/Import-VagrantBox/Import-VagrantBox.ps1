Function Import-VagrantBox
{
    [CmdletBinding()]             
    param ([Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True,Position=0)]
    [Alias('Box')] #Accept Pipeline input with objects that feed in a property named VagrantBox or a property named Box
    [string]$VagrantBox,
    [Parameter(Mandatory=$True,Position=1)]$DownloadDirectory,
    [Parameter(Mandatory=$False,Position=2)]$ChunkSize=10MB,
    [Parameter(Mandatory=$False,Position=3)]$VagrantProvider="virtualbox"
    )   

    Begin
    {     
        Invoke-Command -ScriptBlock $Global:InvocationTrace
        
        Switch ($True) {
           ($VagrantBox -match '^http')  { $UseHTTPBox = $True }
           (Test-Path $VagrantBox)  { $UseLocalBox = $True }
           default { $UseVagrantCloud = $True }
        }  
    }     


    Process 
    {

        Switch ($True) {
           ($UseVagrantCloud)  { Import-CloudBox -VagrantBox $VagrantBox -DownloadDirectory "$DownloadDirectory";break }
           ($UseHTTPBox)  { Import-HTTPBox -VagrantBox $VagrantBox -DownloadDirectory "$DownloadDirectory";break }
           ($UseLocalBox)  { Import-LocalBox -VagrantBox $VagrantBox -DownloadDirectory "$DownloadDirectory";break }
           default { 
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.notsupported))) -Err
            break 
          }
        }

    }
    End 
    {
        # From https://ss64.com/ps/export-modulemember.html
        # Export-ModuleMember specifies the module members (such as cmdlets, functions, variables, and aliases) that are exported from a script module (.psm1) file, or from a dynamic module created by using the New-Module cmdlet.
        # This cmdlet can be used only in a script module file or a dynamic module.
        # If a script module does not include an Export-ModuleMember command, the functions in the script module are exported, but the variables and aliases are not. When a script module includes Export-ModuleMember commands, only the members specified in the Export-ModuleMember commands are exported. You can also use Export-ModuleMember to suppress or export members that the script module imports from other modules.    
        Export-ModuleMember Import-VagrantBox
    }    
}