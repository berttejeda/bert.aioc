# Script Start
"Starting Console ..."
# See if we launched console with a different shell argument
$LaunchShell = $args[0]
if (Test-Path ".debugon"){
    $DebugPreference = "Continue"
}
# Determine the shell to launch based on the supplied arguments to this .bat script
$APP_DIR = $([System.IO.Path]::GetFullPath('.'))
Switch ($True) { (-not $(Get-Variable -name IsWindows)) { $Global:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows;break} (-not $(Get-Variable -name IsLinux)) { $Global:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux } (-not $(Get-Variable -name IsMacOS)) { $Global:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS } (-not $(Get-Variable -name IsCoreCLR)) { $Global:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core' } default {break;}
}
if ($IsWindows) {$Global:MyMachineName = $env:computername} elseif ($IsLinux -or $IsMacOS) { $Global:MyMachineName = $env:HOSTNAME }
$env:PSModulePath="$($env:PSModulePath);$PWD\lib\powershell\Modules;$HOME\git\self\powershell.Modules"
Import-Module -Name "$PWD\lib\powershell\Meta\ScriptBlocks" -ErrorAction Stop -DisableNameChecking -force;$Global:AIOLoadedModules += "ScriptBlocks,"
Import-Module -Name "$PWD\lib\powershell\Modules\Invoke-Logger" -ErrorAction Stop -DisableNameChecking -force;$Global:AIOLoadedModules += "Invoke-Logger,"
Import-Module -Name "$PWD\lib\powershell\Modules\EPS" -ErrorAction Stop -DisableNameChecking -force;$Global:AIOLoadedModules += "EPS,"
Import-Module -Name "$PWD\lib\powershell\Modules\PSYaml" -ErrorAction Stop -DisableNameChecking -force;$Global:AIOLoadedModules += "PSYaml,"

function Import-PSModules() {
    Write-Host "Importing Powershell Modules from $($args[0]) ..." -ForegroundColor Yellow -BackgroundColor Black
    $ModuleObjects = Get-ChildItem -recurse "$($args[0])" -Include ('*.psd1', '*.psm1')
    $ModuleObjects  | ForEach-Object {
        try {
            Import-Module -Name $($_.Directory) -ErrorAction Stop -DisableNameChecking -force
            if ($_.BaseName -notin $AIOLoadedModules){
                Write-Host "Imported $($_.BaseName)" -ForegroundColor DarkYellow -BackgroundColor Black
                $Global:AIOLoadedModules += "$($_.BaseName),"
            }            
        } catch {
            Write-Debug "Skipped $($_.Directory) as it failed to import with error: $_"
        }
    }
}
# Initialize Default Variables
Write-Host "Reading default settings files (etc\settings\*.yaml)"
# Read Settings Files
$Private:SettingsFiles = @()
$Settings = New-Object PSObject
ForEach ($Private:SettingsFile in $(Get-ChildItem -recurse -path "$PWD\etc\settings\*.yaml")){
    $SettingsFileContent = Get-Content $SettingsFile.FullName -Raw
    if ($SettingsFileContent -eq $Null -or $SettingsFileContent -eq "") {
        Invoke-Logger "Skipping $($SettingsFile.FullName), as it is empty!" -warn
        continue
    }
    $Settings | Add-Member -type NoteProperty -Name $SettingsFile.BaseName -Value $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Template $SettingsFileContent))
}
ForEach ($Private:OverrideDir in $Settings.defaults.user_overrides_dirs){
    if (Test-Path "$OverrideDir"){
        Write-Host "Reading settings files from user-overrides $OverrideDir"
        ForEach ($Private:SettingsFile in $(Get-ChildItem -recurse -path "$OverrideDir\*.yaml")){
         $SettingsFileContent = Get-Content $SettingsFile.FullName -Raw
         if ($SettingsFileContent -eq $Null -or $SettingsFileContent -eq "") {
             Invoke-Logger "Skipping $($SettingsFile.FullName), as it is empty!" -warn
             continue
         }         
         $Settings | Add-Member -type NoteProperty -Name $SettingsFile.BaseName -Value $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Template $SettingsFileContent))
        }
    }
}

Write-Host "Loading global internationalizations" -ForegroundColor Yellow -BackgroundColor Black
$i18n = [PSCustomObject]@{}    
Add-Member -InputObject $settings -type NoteProperty -Name i18n -Value $i18n
# Find locale directories
ForEach ($Private:LocaleFolder in $(Get-ChildItem -path "$PWD\etc\i18n\translations" | Where-Object {$_ -is [System.IO.DirectoryInfo]})){
    $LocalePropertyName = $LocaleFolder.Name
    Invoke-Expression "`$$LocalePropertyName = [PSCustomObject]@{}"
    Add-Member -InputObject $(Invoke-Expression "`$settings.i18n") -type NoteProperty -Name $LocalePropertyName -Value $(Invoke-Expression "`$$LocalePropertyName" )
    ForEach ($Private:LocaleFileFile in $(Get-ChildItem -recurse -path "$($LocaleFolder)" -Include "*.yaml")){
        $LocaleFileFileContent = Get-Content $LocaleFileFile.FullName -Raw
        if ($LocaleFileFileContent -eq $Null -or $LocaleFileFileContent -eq "") {
            Invoke-Logger "Skipping $($LocaleFileFile.FullName), as it is empty!" -warn
            continue
        }        
        $LocaleSetting = $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Template $LocaleFileFileContent))
        $LocaleSettingName = $LocaleFileFile.BaseName
        Add-Member -InputObject $(Invoke-Expression "`$settings.i18n.$($LocalePropertyName)") -type NoteProperty -Name $LocaleSettingName -Value $LocaleSetting
    }
}
Import-Module -Name "$PWD\lib\powershell\Modules\List-Requirements" -ErrorAction Stop -DisableNameChecking -force
# Account for shell argument (if applicable)
if ($LaunchShell.length -gt 0){
# Clear the screen
    clear-host
# Adjust the PATH Variable
    $env:PATH+=';'
    $env:PATH+=$([String]::Join(';', $Settings.defaults.paths))
    if ($LaunchShell -ne "powershell"){
        ForEach ($app in $Settings.shells.$LaunchShell.apps){
            if ($(Stat-App $app.binary)){
                Write-Host "Found $($app.binary)"
                Invoke-Expression "&'$($app.binary)' $($app.command)"
                exit 0
            }
        }
        $ExecutionContext.InvokeCommand.ExpandString($Settings.shells.$LaunchShell.notfound)
        exit 1
    }    
}

# Import Powershell Modules
Write-Host "Importing Powershell Modules" -ForegroundColor Yellow -BackgroundColor Black
Import-PSModules "$PWD\lib\powershell\Modules"
Import-PSModules "$PWD\lib\powershell\Tools"

# Initialize Providers
Write-Host "Initializing providers ..." -ForegroundColor Yellow -BackgroundColor Black
Get-ChildItem -Path "$PWD\lib\machine\providers" | Where-Object { 
    $_ -is [System.IO.DirectoryInfo] 
} | ForEach-Object {
    $ProviderObject = $_
    Import-PSModules $ProviderObject.FullName
    $ProviderObjectName = "$($ProviderObject.BaseName)"
    Invoke-Expression "`$$ProviderObjectName = [PSCustomObject]@{}"
    ForEach ($Private:SettingsFile in $(Get-ChildItem -recurse -path "$($ProviderObject.FullName)\etc\settings" -Include "*.yaml")){
        $SettingsFileContent = Get-Content $SettingsFile.FullName -Raw
        if ($SettingsFileContent -eq $Null -or $SettingsFileContent -eq "") {
            Invoke-Logger "Skipping $($SettingsFile.FullName), as it is empty!" -warn
            continue
        }        
        $Setting = $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Template $SettingsFileContent))
        Add-Member -InputObject $(Invoke-Expression "`$$ProviderObjectName") -type NoteProperty -Name $SettingsFile.BaseName -Value $Setting
    }
    Write-Host "Loading machine provider internationalizations" -ForegroundColor Yellow -BackgroundColor Black
    $i18n = [PSCustomObject]@{}    
    Add-Member -InputObject $(Invoke-Expression "`$$ProviderObjectName") -type NoteProperty -Name i18n -Value $i18n
# Find locale directories
    $ProviderTranslationsFolder = "$($ProviderObject.FullName)\etc\i18n\translations"
    if (Test-Path "$ProviderTranslationsFolder"){
        ForEach ($Private:LocaleFolder in $(Get-ChildItem -path "$ProviderTranslationsFolder" | Where-Object {$_ -is [System.IO.DirectoryInfo]})){
            $LocalePropertyName = $LocaleFolder.Name
            Invoke-Expression "`$$LocalePropertyName = [PSCustomObject]@{}"
            Add-Member -InputObject $(Invoke-Expression "`$$ProviderObjectName.i18n") -type NoteProperty -Name $LocalePropertyName -Value $(Invoke-Expression "`$$LocalePropertyName" )
            ForEach ($Private:LocaleFileFile in $(Get-ChildItem -recurse -path "$($LocaleFolder)" -Include "*.yaml")){
                $LocaleFileFileContent = Get-Content $LocaleFileFile.FullName -Raw
                if ($LocaleFileFileContent -eq $Null -or $LocaleFileFileContent -eq "") {
                    Invoke-Logger "Skipping $($LocaleFileFile.FullName), as it is empty!" -warn
                    continue
                }        
                $LocaleSetting = $(ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Template $LocaleFileFileContent))
                $LocaleSettingName = $LocaleFileFile.BaseName
                Add-Member -InputObject $(Invoke-Expression "`$$ProviderObjectName.i18n.$($LocalePropertyName)") -type NoteProperty -Name $LocaleSettingName -Value $LocaleSetting
            }
        }
    }
}
# Clear the screen
SafelyClear-Host
# Process Project Requirements
List-AppRequirements
# Run any Pre-Startup Options
Invoke-Logger "Invoking any Pre-Startup Actions (if applicable)"
Invoke-StartupTasks $Settings.pre_startup.tasks
# Get Machine Definitions
$MachineDefinitionSet = Get-MachineDefinitions -MachineEnvironment $Settings.environment.current.path
Invoke-Logger "Ensuring any VMs with auto-start set to 'True' are booted up ..." -Color Magenta
# Build Local Lab
ForEach ($private:MachineDefinition in $MachineDefinitionSet){
    If ([System.Convert]::ToBoolean($MachineDefinition.vars.auto_start)){
        try {
            Invoke-Logger "$($MachineDefinition.name) is configured for autostart" -Color Magenta
            $_machine_workspace = Join-Path -Path "$([Environment]::GetFolderPath('MyDocuments'))" -ChildPath "aio"
            $machine_workspace = Join-Path -Path "$($_machine_workspace)" -ChildPath "$($Settings.environment.current.name)\$($MachineDefinition.name)"
            If (-Not $(Test-Path "$machine_workspace")) {
                Invoke-Logger "Creating machine workspace $machine_workspace ..." -Color Magenta
                New-Item "$machine_workspace" -ItemType Directory | Out-Null
            }             
            If ([System.Convert]::ToBoolean($MachineDefinition.vars.auto_start_no_prompt)){
                Invoke-Logger "auto_start_no_prompt is set to true"
                Invoke-Logger "Starting $($MachineDefinition.name)"
                Create-Machine -MachineName $MachineDefinition.name -MachineEnvironment $MachineDefinition.environment
            } else {
                if ($(-Not $((List-Machine $MachineDefinition.name -AsObject).State -in @("Running","Ready")))){
                    $proceed = Read-Host "Do you want to initialize/start this machine? (Y/N)"
                    if ($proceed.tolower() -eq 'y') {
                        Create-Machine -MachineName $MachineDefinition.name -MachineEnvironment $MachineDefinition.environment
                    } else {
                        break
                    }     
                } else {
                    Invoke-Logger "$($MachineDefinition.name) is already in a running state" -Color Magenta
                }
            }
            if (Get-Variable "MachineObj" -Scope Global -ErrorAction SilentlyContinue){
                Remove-Variable MachineObj -Scope Global
            }            
            Invoke-Logger "$($MachineDefinition.name) OK ..." -Color Magenta
        } catch {
            Invoke-Logger "Error during initialization of $($MachineDefinition.name)" -Err
            Invoke-Logger $_.Exception.Message -Err
            Invoke-Logger "Line - $($_.InvocationInfo.Line)" -Err
            Invoke-Logger "PositionMessage - $($_.InvocationInfo.PositionMessage)" -Err
            Invoke-Logger "Command - $($_.InvocationInfo.MyCommand)" -Err
            Invoke-Logger "PSCommandPath - $($_.InvocationInfo.PSCommandPath)" -Err
            Invoke-Logger "ScriptName - $($_.InvocationInfo.ScriptName)" -Err
            Invoke-Logger "Machine defintion file - $($MachineDefinition.definition_file)" -Err
        }
    }
}
# Run any Post-Startup Options
Invoke-Logger("Invoking any Post-Startup Actions (if applicable)")
Invoke-StartupTasks $Settings.post_startup.tasks
# Show Banner
Show-Banner
# Set Window Title
if ($isAdmin) {    
    $Host.UI.RawUI.WindowTitle += "AIO Admin Console - PowerShell {0} - [ADMIN]" -f $PSVersionTable.PSVersion.ToString()
} else {
    $Host.UI.RawUI.WindowTitle = "AIO Admin Console - PowerShell {0}" -f $PSVersionTable.PSVersion.ToString()
}
# Adjust the PATH Variable
$env:PATH+=';'
$env:PATH+=$([String]::Join(';', $Settings.defaults.paths))