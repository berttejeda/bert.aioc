Function Read-Config {
[CmdletBinding()]             
param ([Parameter(Mandatory=$True, 
    ValueFromPipelineByPropertyName=$True,Position=0)][Alias('FullName')]$ConfigPath, #Accepts Pipeline input with objects that feed in a property named FullName or a property named File
[Parameter(Mandatory=$False,Position=1)]$Scope="Global",
[Parameter(Mandatory=$False,Position=2)][string[]]$Log,
[switch]$VerifyOnly
)
    Begin
    {   
        $ConfigFolder = Split-Path -parent $ConfigPath
        $ConfigName = Split-Path -leaf $ConfigPath
        if (!$(Test-Path $ConfigPath)) {
            throw [System.Exception] "$ConfigPath not found"
        }
        $ConfigExt = $(Get-Item $ConfigPath).Extension
        #region Logging facility
        if (Get-Command Invoke-Logger -ErrorAction 'SilentlyContinue')
        {
            $Logger = {Invoke-Logger $args[0] -Log $args[1]}
        } else 
        {
            $Logger = {
                if (($args[1]) -and (Test-Path $args[1] -ErrorAction SilentlyContinue))
                {
                    Write-Host $args[0] | Add-Content $args[1]
                } else 
                {
                    Write-Host "$($args[0]) - Warning, No log Specified"
                }
            }
        }
        if (Get-Command Resolve-ErrorRecord -ErrorAction 'SilentlyContinue')
        {
            $ErrLogger = {$Logger.Invoke($(Resolve-ErrorRecord $args[0]),$args[1])}
        } else 
        {
            $ErrLogger = {throw [System.Exception] $args[0]}
        }
        #enregion Logging facility
    }
    Process {
        Switch ($ConfigExt) {
           ".ini"  { Read-INI $ConfigPath; break}
           ".yml"  { Read-Yaml $ConfigPath; break}
           ".yaml"  { Read-Yaml $ConfigPath; break}
           default {"Unsupported File Extension $($ConfigExt)"; break}
        }
    }
    End 
    {
    }
}