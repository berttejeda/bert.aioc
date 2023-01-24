Function List-AppRequirements {
    param(
        [Parameter(Mandatory=$False,Position=0,
        HelpMessage="Requirements is an Array of App definitions")]
        [Alias('apps')]
        $AppRequirements=$Settings.requirements.apps
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    if ($isLinux) {
        $OS="Linux"
    } else {
        $OS=$((Get-CimInstance -ClassName Win32_OperatingSystem).caption)
    }

    Switch -Wildcard ($OS) {
       "*Windows 7*"  { List-Win7Requirements; break}
       "*Windows 8*"   {List-Win8Requirements; break}
       "*Windows 10*" {List-Win10Requirements; break}
       "*Linux*" {List-LinuxRequirements; break}
       default {Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.os))) -Warn; break}
    }    

    ForEach ($app in $AppRequirements) {
        If ($app.install_check) {
            If (-not $(Invoke-Expression $app.install_check) -and ($app.os -eq "windows" -and -not $isLinux)) {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.app_not_found))) -Warn
                $result = Read-Host -Prompt "Do you want to install this application? [y/n]"
                If ($result.ToLower() -match "y|yes"){
                    try {
                        Invoke-Expression $app.install_cmd
                    } catch {
                    }
                } Else {
                    If ([System.Convert]::ToBoolean($app.required)){
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.app_install))) -Warn
                        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.functionality))) -Warn
                    }
                } 
            }
        }

    }    

}

