<#
.SYNOPSIS
=============================================
Created with: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.1.21
Created on:   7/2/2014 6:18 PM
Created by:   Bert Tejeda
Organization:
Email:
Keywords:
FUNCTION.......:  Read-Config
PURPOSE........:  General purpose .ini configruation reader
REQUIREMENTS...:  If modular form (.psm1), must import this module via Import-Module
=============================================
.DESCRIPTION
Reads a .ini configruation file and imports all variables defined therein
.INPUTS
Path to Configuration file
.OUTPUTS
Hashtable
Read-Config returns a hashtable
.EXAMPLE
Read-Config MyConfig.ini
This command reads the specified .ini configuration file and creates PowerShell variables according to the Key=Value pairs
#>
# -----------------------------------------------------------------------------
# Function      : Read-Config
# -----------------------------------------------------------------------------
# Description   : Reads the specified .ini configuration file
# Parameters    : 
# Returns       : Hashtable
# Credits       : Bert Tejeda
# -----------------------------------------------------------------------------
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