#######################################
#         PowerShell Aliases - Default
# Sometimes Powershell can't run commands unless they're wrapped in a function
# http://stackoverflow.com/questions/38981044/the-term-is-not-recognized-as-cmdlet-function-script-file-or-operable-program
#######################################

# package="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -sta -noprofile -ExecutionPolicy Unrestricted -File "%~dp0scripts\$1.ps1" -package $2
# firewall.open=netsh advfirewall firewall add rule name="$1" dir=in action=allow protocol="$2" localport="$3"

# Set up command prompt and window title. Use UNIX-style convention for identifying 
# whether user is elevated (root) or not. Window title shows current version of PowerShell
# and appends [ADMIN] if appropriate for easy taskbar identification
function prompt 
{ 
    if ($isAdmin) 
    {
        "[" + (Get-Location) + "] # " 
    }
    else 
    {
        "[" + (Get-Location) + "] $ "
    }
}


# Edit Your PowerShell Profile
function Edit-Profile
{
    if ($host.Name -match "ise")
    {
        $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
    }
    else
    {
        notepad $profile.CurrentUserAllHosts
    }
}