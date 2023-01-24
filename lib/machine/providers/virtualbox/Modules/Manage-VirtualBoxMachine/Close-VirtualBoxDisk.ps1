Function Close-VirtualBoxDisk {
    param(
    [Parameter(Mandatory=$True,Position=0)]$DiskObjData
    )     

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if (-not $virtualbox.environment.VboxManageAvailable) {
        throw [System.Exception] $(Expand-String $virtualbox.i18n.enUS.General.errors.vbox_cli.not_found)
    }

    $disksObjects = @{}
    $DiskObjData = $DiskObjData.split(' ')
    ForEach ($pair in $DiskObjData)
    {
        $element=@{}
        $element= $pair.split(",")
        $disksObjects.add($element[0], $element[1])
    }    
    ForEach($disk in $disksObjects){
      If($disk.State -eq "inaccessible"){
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.disk.closing))) -Logfiles $MachineObj.logfile
        &$VboxManage closemedium disk $disk.UUID
      }
    }
} 