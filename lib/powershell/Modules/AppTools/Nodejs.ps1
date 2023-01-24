#######################################
#         PowerShell Aliases for NodeJS
# Sometimes Powershell can't run commands unless they're wrapped in a function
# http://stackoverflow.com/questions/38981044/the-term-is-not-recognized-as-cmdlet-function-script-file-or-operable-program
#######################################

# npmls
function listNpmGlobalModules() {
    npm ls -g --depth=0
}
Set-Alias -name "npmls" -value "listNpmGlobalModules"