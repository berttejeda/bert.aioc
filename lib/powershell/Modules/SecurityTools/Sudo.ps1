if (-not $isLinux){
    # Find out if the current user identity is elevated (has admin rights)
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Simple function to start a new elevated process. If arguments are supplied then 
    # a single command is started with admin rights; if not then a new admin instance
    # of PowerShell is started.
    function admin
    {
        if ($args.Count -gt 0)
        {   
           $argList = "& '" + $args + "'"
           Start-Process "$psHome\powershell.exe" -Verb runAs -ArgumentList $argList
        }
        else
        {
           Start-Process "$psHome\powershell.exe" -Verb runAs
        }
    }

    # Set UNIX-like aliases for the admin command, so sudo <command> will run the command
    # with elevated rights. 
    Set-Alias -Name su -Value admin
    Set-Alias -Name sudo -Value admin

    # We don't need these any more; they were just temporary variables to get to $isAdmin. 
    # Delete them to prevent cluttering up the user profile. 
    Remove-Variable identity
    Remove-Variable principal
}