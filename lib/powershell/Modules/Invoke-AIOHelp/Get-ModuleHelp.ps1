function Get-ModuleHelp {
    <#
        .SYNOPSIS
            Get all the commands from a (set of) module(s), with a short synopsis of their functionality
        .DESCRIPTION
            Runs Get-Command and Get-Help against all the commands in the specified module(s), and outputs the results in a way that makes it easy to examine and decide which commands you need from a new module. Note that running Get-Help generally imports the module, so you should take care. 
            
            Never install a module you don't trust into your PowerShell module path.
        .EXAMPLE
            Get-ModuleHelp Microsoft.* | Sort ModuleName | Format-Table -Group ModuleName
            
            Lists the commands from multiple modules, grouped by module, with a synopsis
        .EXAMPLE
            Get-ModuleHelp * | Sort ModuleName | 
                Select ModuleName, Verb, Noun, Name, Synopsis |
                ConvertTo-Html -PostContent '<script src="https://cdn.rawgit.com/stevesouders/5952488/raw/activetable.js"></script>' |
                Set-Content MicrosoftCommands.html
                
            Creates an HTML report (with a sortable table) from all of the modules available on your system. This may take awhile to load, but when it's done you'll have a searchable, sortable list of commands, with a short synopsis for each about what it does.
    #>
    [CmdletBinding()]
    param(
        # The name of the module to get help for
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string[]]$Module
    )
    begin {
        $display = [System.Management.Automation.PSPropertySet]::new( "DefaultDisplayPropertySet", [string[]]@("Name", "Synopsis"))
    }
    process {
        Get-Command -Module $Module | Select *, @{ Name = "Synopsis"; Expr = { (Get-Help $_.Name).Synopsis.Trim() }} | 
            # For display purposes...
            Add-Member MemberSet PSStandardMembers $display -Passthru
    return $display
    }
}