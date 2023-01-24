# Set the Current Module's Working Path
$MyPSScriptRoot = $PSScriptRoot
# Invoke the ModuleLoader Script Block (See console.bat)
Invoke-Expression -Command $Global:ModuleLoader.ToString()