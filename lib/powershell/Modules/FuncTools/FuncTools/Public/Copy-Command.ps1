Function Copy-Command {

    [cmdletbinding()]
    [alias("cc")]
    [OutputType([system.string[]])]

    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "Enter the name of a PowerShell command")]
        [ValidateNotNullorEmpty()]
        [string]$Command,
        [Parameter(Position = 1, HelpMessage = "Enter the new name for your command using Verb-Noun convention")]
        [ValidateNotNullorEmpty()]
        [string]$NewName,
        [switch]$IncludeDynamic,
        [switch]$AsProxy,
        [switch]$CallDefaults,
        [switch]$UseForwardHelp
    )

    Try {
        Write-Verbose "[BEGIN ] Starting: $($MyInvocation.Mycommand)"
        Write-Verbose "[BEGIN ] Getting command metadata for $command"
        $gcm = Get-Command -Name $command -ErrorAction Stop
        #allow an alias or command name
        if ($gcm.CommandType -eq 'Alias') {
            $cmdName = $gcm.ResolvedCommandName
        }
        else {
            $cmdName = $gcm.Name
        }
        Write-Verbose "[BEGIN ] Resolved command to $cmdName"
        $cmd = New-Object System.Management.Automation.CommandMetaData $gcm
    }
    Catch {
        Write-Warning "Failed to create command metadata for $command"
        Write-Warning $_.Exception.Message
    }

    if ($cmd) {
        #create the metadata

        if ($NewName) {
            $Name = "Global:$NewName"
        }
        else {
            $Name = "Global:$($cmd.Name)"
        }

        #define a formatted metadata comment block
        $myComment = @"
<#
This is an alias function of:
 
$(($gcm | Format-Table -AutoSize | Out-String).trim())
 
Created: $('{0:dd} {0:y}' -f (get-date))
Author : $env:username
 
#>
 
"@

        #define the beginning of text for the new command
        #dynamically insert the command's module if one exists
        $text = @"
#requires -version $(([regex]"\d+\.\d+").match($psversiontable.psversion).value)
$(if ($gcm.modulename -AND $gcm.modulename -notmatch "Microsoft\.PowerShell\.\w+") { "#requires -module $($gcm.modulename)" })
 
$myComment
 
Function $Name {
 
"@

        #manually copy parameters from original command if param block not found
        #this can happen with dynamic parameters like those in the AD cmdlets
        if (-Not [System.Management.Automation.ProxyCommand]::GetParamBlock($gcm)) {
            Write-Verbose "[PROCESS] No param block detected. Looking for dynamic parameters"
            $IncludeDynamic = $True
        }

        if ($IncludeDynamic) {
            Write-Verbose "[PROCESS] Adding dynamic parameters"
            $params = $gcm.parameters.GetEnumerator() | where-object { $_.value.IsDynamic}
            foreach ($p in $params) {
                $cmd.Parameters.add($p.key, $p.value)
            }
        }

        if ($UseForwardHelp) {
            #define a regex to pull forward help from a proxy command
            [regex]$rx = "\.ForwardHelp.*\s+\.ForwardHelp.*"
            Write-Verbose "[PROCESS] Using forwarded help"
            $help = $rx.match([System.Management.Automation.ProxyCommand]::Create($cmd)).Value
        }
        else {
            #if not using the default Forwardhelp links, get comment based help instead
            #get help as a comment block
            $help = [System.Management.Automation.ProxyCommand]::GetHelpComments((get-help $Command))
            #substitute command name
            $help = $help -replace $Command, $NewName

            #remove help link
            $cmd.HelpUri = $null
        }

        Write-Verbose "[PROCESS] Adding Help"
        $Text += @"
<#
$help
#>
 
"@
        Write-Debug "Help is $help"
        #cmdletbinding
        $Text += [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($cmd)

        #get parameters
        $NewParameters = [System.Management.Automation.ProxyCommand]::GetParamBlock($cmd)

        Write-Verbose "[PROCESS] Cleaning up parameter names"
        [regex]$rx = '\]\r\s+\${(?<var>\w+)}'
        #replace the {variable-name} with just variable-name and joined to type name
        $NewParameters = $rx.Replace($NewParameters, ']$$${var}')

        #Insert parameters
        $Text += @"
 
Param(
$NewParameters
)
 
Begin {
 
    Write-Verbose "[BEGIN ] Starting `$(`$MyInvocation.Mycommand)"
    Write-Verbose "[BEGIN ] Using parameter set `$(`$PSCmdlet.ParameterSetName)"
    Write-Verbose (`$PSBoundParameters | Out-String)
 
"@

        Write-Verbose "[PROCESS] Adding Begin block"

        if ($AsProxy) {
            $Text += [System.Management.Automation.ProxyCommand]::GetBegin($cmd)
        }

        $Text += @"
 
} #begin
 
Process {
 
 
"@

        Write-Verbose "[PROCESS] Adding Process block"
        if ($AsProxy) {
            $Text += [System.Management.Automation.ProxyCommand]::GetProcess($cmd)
        }
        else {

            if ($CallDefaults) {
                $Text += @"
    `$DefaultParams = @{}
    foreach(`$h in `$MyInvocation.MyCommand.Parameters.GetEnumerator()) {
        try {
            `$key = `$h.Key
            `$val = Get-Variable -Name `$key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
            if (([String]::IsNullOrEmpty(`$val) -and (!`$PSBoundParameters.ContainsKey(`$key)))) {
                throw "A blank value that wasn't supplied by the user."
            }
            Write-Verbose "`$key => '`$val'"
            `$DefaultParams[`$key] = `$val
        } catch {}
    }                
    $($cmd.name) @DefaultParams
"@
            } else {
                $Text += @"
    $($cmd.name) @PSBoundParameters
"@            
            }

        }

        $Text += @"
 
 
} #process
 
End {
 
    Write-Verbose "[END ] Ending `$(`$MyInvocation.Mycommand)"
 
"@

        Write-Verbose "[PROCESS] Adding End block"
        If ($AsProxy) {
            $Text += [System.Management.Automation.ProxyCommand]::GetEnd($cmd)
        }

        $Text += @"
 
} #end
 
"@

        #insert closing text
        $Text += @"
 
} #end function $Name
"@
        if ($host.Name -match "PowerShell ISE") {
            #open in a new ISE tab
            $tab = $psise.CurrentPowerShellTab.Files.Add()

            Write-Verbose "[END ] Opening new command in a new ISE tab"
            $tab.editor.InsertText($Text)

            #jump to the top
            $tab.Editor.SetCaretPosition(1, 1)
        }
        elseif ($host.name -eq 'Visual Studio Code Host') {
            $pseditor.workspace.newfile()
            $pseditor.GetEditorContext().currentfile.insertText($text)
        }
        else {
            #just write the new command to the pipeline
            $Text
        }
    }
    Write-Verbose "[END ] $($MyInvocation.MyCommand)"

}
