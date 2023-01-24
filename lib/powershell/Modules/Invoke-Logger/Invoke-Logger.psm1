# Load Internationalizations
$LocalRootPropertyName = (Get-Item $PSScriptRoot\$($MyInvocation.MyCommand)).BaseName -Replace('-|_','')
Write-Debug "Loading Global internationalizations for $LocalRootPropertyName" -debug
$LocaleFolder = "$PSScriptRoot\i18n\translations\$($settings.defaults.locale)"
if (Test-Path $LocaleFolder) {
    ForEach ($Private:LocaleFileFile in $(Get-ChildItem -recurse -path "$LocaleFolder" -Include "*.yaml")){
        $LocaleFileFileContent = Get-Content $LocaleFileFile.FullName -Raw
        if ($LocaleFileFileContent -eq $Null -or $LocaleFileFileContent -eq "") {
            Write-Debug "Skipping $($LocaleFileFile.FullName), as it is empty!"
            continue
        }
        $LocaleSetting = $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Template $LocaleFileFileContent))
        $LocaleSettingName = $LocaleFileFile.BaseName
        if (-not $(Invoke-Expression "[bool](`$settings.i18n.$($settings.defaults.locale).PSobject.Properties -match `"$LocalRootPropertyName`")")){
            Invoke-Expression "`$$LocalRootPropertyName = [PSCustomObject]@{}"
            Add-Member -InputObject $(Invoke-Expression "`$settings.i18n.$($settings.defaults.locale)") -type NoteProperty -Name $LocalRootPropertyName -Value $(Invoke-Expression "`$$LocalRootPropertyName" )
        }
        Add-Member -InputObject $(Invoke-Expression "`$settings.i18n.$($settings.defaults.locale).`"$LocalRootPropertyName`"") -type NoteProperty -Name $LocaleSettingName -Value $LocaleSetting -Force
    }

}
# Import Per-Module Functions
$NoExport = 'NULL'
$ModuleFunctions = @(Get-ChildItem -Path $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue)
$ToExport = $ModuleFunctions | Where-Object { $_.BaseName -notin $NoExport } | Select-Object -ExpandProperty BaseName
# Dot-source the files.
foreach ($import in $ModuleFunctions) {
    try {
        Write-Debug "Importing $($import.FullName)"
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}