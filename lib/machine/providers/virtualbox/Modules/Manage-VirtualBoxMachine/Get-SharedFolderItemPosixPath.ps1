Function Get-SharedFolderItemPosixPath {

    # We want to ensure that the file specified 
    # is indeed located in the root path 
    # of at least one the virtual machine's shared folders

    param(
    [Parameter(Mandatory=$True,Position=0)]$MachineObj,
    [Parameter(Mandatory=$True,Position=1)]$FileObj
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace
    $APP_DIR_SHARE = [PSCustomObject] @{
    name        =   $virtualbox.defaults.shared_folders.program_dir_name
    host_path   =   $APP_DIR
    }
    $SharedFolders = $MachineObj.vars.shared_folders + $APP_DIR_SHARE
    ForEach ($SharedFolder in $SharedFolders) {
        if ($FileObj.FullName.Contains($SharedFolder.host_path)) {
            $FilePathSanitized = ($FileObj.FullName).Replace($SharedFolder.host_path,'') -Replace("\\","/")
            $FilePosixPath = '{0}/{1}_{2}/{3}' -f $virtualbox.defaults.shared_folders.mountpath,$virtualbox.defaults.shared_folders.prefix,$SharedFolder.name, $FilePathSanitized
            $FilePosixPath = $FilePosixPath -Replace("//","/")
        }
    }

    if (!$FilePosixPath){
        $SharedFolderList = $($MachineObj.vars.shared_folders | %{"- $($_.host_path)"}) -Join("`n")
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.unavailable)))
    }   

    return $FilePosixPath 

}