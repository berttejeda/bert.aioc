function Get-VirtualBoxMachineStates {

    if (-not $($virtualbox.environment.VboxManageAvailable)) {
        return @{}
    }
    
    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if (-not $virtualbox.environment.VboxManageAvailable) {
        throw [System.Exception] $(Expand-String $virtualbox.i18n.enUS.General.errors.vbox_cli.not_found)
    }
    
    # $MachineStatePattern:
    # - Either of the following 
    #   - contains the string 'Name:' (skipping if the match is followed by a comma at any point after the match)
    #   - contains the string 'State' followed by the word 'since' at any point after the match
    $MachineStatePattern = "Name:(?!.*,)|State.*since"
    $MachineStates = (&$virtualbox.defaults.VboxManagePath list vms --long | Select-String -CaseSensitive  $MachineStatePattern | Out-String) -Replace('\(.*\)| ','') -Replace "`n","," -Replace "`r",","
    $MachineStates = $MachineStates.Split(',')
    $t = 0
    $MachineStateData = "Name,State`n"
    ForEach ($MachineState in $MachineStates){
        if ($MachineState){
            $element = $MachineState.split(':')
            switch ($True){
             ($element[0] -eq "Name") { $MachineStateData += "$($element[1])";$t++ }
             ($element[0] -eq "State"){ $MachineStateData += ",$($element[1])";$t++ }
             ($t -gt 1) { $MachineStateData += "`n"; $t = 0  }
             default { continue }
            }
        }
    }
    $MachineStates = $MachineStateData | ConvertFrom-Csv
    return $MachineStates
}