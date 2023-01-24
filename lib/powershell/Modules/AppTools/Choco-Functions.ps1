#######################################
#         PowerShell Aliases for the chocolatey package manager
# Sometimes Powershell can't run commands unless they're wrapped in a function
# http://stackoverflow.com/questions/38981044/the-term-is-not-recognized-as-cmdlet-function-script-file-or-operable-program
#######################################

function choco.upgrade.all() {
    choco upgrade all
}
Set-Alias -name "update" -value "choco.upgrade.all"

function choco.list.local() {
    choco list --local-only
}
Set-Alias -name "chocolist" -value "choco.list.local"