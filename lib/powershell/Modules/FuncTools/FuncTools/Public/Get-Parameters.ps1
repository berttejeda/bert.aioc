function Get-Parameters {
    [CmdletBinding()]
    Param (
    [Parameter(Mandatory,ValueFromPipeline)]
    [string]$Function
    )

    begin {
    $Parameters = @()
    $Common = @(
        'Debug',
        'ErrorAction',
        'ErrorVariable',
        'InformationAction',
        'InformationVariable',
        'OutVariable',
        'OutBuffer',
        'PipelineVariable',
        'Verbose',
        'WarningAction',
        'WarningVariable',
        'WhatIf',
        'Confirm'
    )
    }

    process {
    try {
        $Params = (Get-Command $Function).Parameters | Select-Object -ExpandProperty Keys
    } catch {
        Write-TSWarning $_ -Verbose:$VerbosePreference
        throw
    }

    $Params | Where-Object {
        if (!$Common.Contains($_)) {
        $Name = $_
        $Help = Get-Help $Function -Parameter $_
        $Desc = $Help.Description.Text
        $Parameters += [PSCustomObject]@{
            Name = $Name
            Description = $Desc
        }
        }
    }
    }

    end {
    Write-Output $Parameters
    }
}