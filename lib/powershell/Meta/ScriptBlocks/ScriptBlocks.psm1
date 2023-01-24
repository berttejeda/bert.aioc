# Import Per-Module Functions
$NoExport = 'NULL'
$ModuleFunctions = @(Get-ChildItem -Path $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue)
$ToExport = $ModuleFunctions | Where-Object { $_.BaseName -notin $NoExport } | Select-Object -ExpandProperty BaseName
# Dot-source the files.
foreach ($import in $ModuleFunctions) {
    try {
        Write-Verbose "Importing $($import.FullName)"
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}