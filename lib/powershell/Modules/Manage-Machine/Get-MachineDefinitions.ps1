function Get-MachineDefinitions {
    param(
        [Parameter(Mandatory=$False,Position=0)]
        $MachineName,
        [Parameter(Mandatory=$False,Position=1,
        HelpMessage="e.g. environments\myenvironment")]
        [Alias('env','environment')]
        $MachineEnvironment=$Settings.environment.current.path,
        [Parameter(Mandatory=$False,ValueFromPipeline,Position=2)]
        $RawDefinitions,
        [Parameter(Mandatory=$False,ValueFromPipeline,Position=3)]
        $EnvironmentScope="Local"
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.environment_scope))) -debug

    $Private:MachineDefinitions = @()

    if (!$RawDefinitions) {
        Switch ($True) {
            ($EnvironmentScope -eq "All") {
                $MachineEnvironment = "$APP_DIR\$($Settings.defaults.InfrastructureFolderName)\$($Settings.defaults.EnvironmentFolderName)"
                $MachineEnvironmentPath = "$MachineEnvironment\*\machines"
                break
            }
            ($env:AIOMachineEnvironment) {
                if (Test-Path $env:AIOMachineEnvironment){
                    $MachineEnvironment = (Get-Item $env:AIOMachineEnvironment).FullName
                    $MachineEnvironmentPath = "$MachineEnvironment\machines"
                }
                break
            }
            (Test-Path $MachineEnvironment)  { 
                $MachineEnvironment = (Get-Item $MachineEnvironment).FullName
                $MachineEnvironmentPath = "$MachineEnvironment\machines"
                break
            }
            default { 
                $MachineEnvironment = (Get-Item $Settings.environment.current.path).FullName
                $MachineEnvironmentPath = "$MachineEnvironment\machines"
            }
        }

        Switch ($True) {
            ($MachineName.length -gt 0) {
                $MachineDefinitionFiles = Get-ChildItem -recurse -path $MachineEnvironmentPath -Include '*.yaml' | Where-Object { $_.BaseName -eq "$MachineName" }
            }
            default {
                $MachineDefinitionFiles = Get-ChildItem -recurse -path $MachineEnvironmentPath -Include '*.yaml'
            }
        }
        # Fail if we couldn't find any machine definition files
        if (!$MachineDefinitionFiles) {
            throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.definition_not_found)))
        }        

    } else {
        Switch ($True) {
            ($RawDefinitions -is [array]) {
                $MachineDefinitionFiles = $RawDefinitions | Where-Object {
                    $_ -is [System.IO.FileInfo]                 
                }
                break;
            }
            ($RawDefinitions -is [System.IO.DirectoryInfo]) {
                if ($MachineName) {
                    $MachineDefinitionFiles = Get-ChildItem -recurse -path $RawDefinitions -Include '*.yaml' | Where-Object {$_.BaseName -eq "$MachineName"}
                } else {
                    $MachineDefinitionFiles = Get-ChildItem -recurse -path $RawDefinitions -Include '*.yaml'
                }                
                break
            }
            ($RawDefinitions -is [System.IO.FileInfo]) {
                $MachineDefinitionFiles = $RawDefinitions
                break
            }
            ($RawDefinitions -is [String]) {

                if (Test-Path $RawDefinitions){
                    $MachineDefinitionFiles = @(Get-Item $RawDefinitions)
                } else {
                    throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.raw_definition_not_found)))
                }
                break
            }
            default { 
                throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.raw_definition_unsupported)))
            }
        }
    }


    # Fail if we find duplicate machine definitions
    $DuplicateMachines = @{}
    $MachineDefinitionFiles | foreach {
        $DuplicateMachines[$_.BaseName] += 1
    }
    $DuplicateMachines.keys | where {
        $DuplicateMachines["$_"] -gt 1
    } | foreach {
        $CurrMachineName = $_
        $DuplicateObjects = $MachineDefinitionFiles | Where-Object {$_.BaseName -eq $CurrMachineName}
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.duplicate_machine))) -err
        $DuplicatesFound = $True
    }
    if ($DuplicatesFound){
        throw [System.Exception] $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.duplicate_definitions)))
    }
    ForEach ($Global:MachineDefinitionFile in $MachineDefinitionFiles){
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.reading_definition))) -debug
        $MachineDefinitionContent = Get-Content $Global:MachineDefinitionFile.FullName
        if ($MachineDefinitionContent -eq $Null -or $MachineDefinitionContent.length -eq 0) {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.definition_empty))) -warn
            Write-Host $($MachineDefinitionContent -eq $Null)
            Write-Host $($MachineDefinitionContent -eq "")
            continue
        }
        Try {
            if ($isLinux){
                $MachineEnvironmentName = $($MachineDefinitionFile.FullName.split("$($Settings.defaults.EnvironmentFolderName)/")[1]).split('/')[0]
            } else { 
                $MachineEnvironmentName = $($MachineDefinitionFile.FullName.split("$($Settings.defaults.EnvironmentFolderName)\")[1]).split('\')[0]
            }
            $Global:MachineDir = "$($Settings.machine.workdir)\$($MachineDefinitionFile.BaseName)"
            $Private:Definition = ConvertFrom-Yaml -Text $(Invoke-EpsTemplate -Path "$($MachineDefinitionFile.FullName)")
            if ($Definition.length -gt 1) {
                $ExtraDefinitions = $Definition[1..$Definition.length]
                $Definition = $Definition[0]
            }
            if (!$Definition.vars){
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString warn.no_vars_block))) -warn
                continue                
            }
        } Catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.machine_definition_yaml))) -err
            throw $_
        }
        try {
            $Definition['environment'] = $MachineEnvironment
            $Definition['environment_name'] = $MachineEnvironmentName
            $Definition['machine_dir'] = $MachineDir
            $Definition['logfile'] = "$MachineDir\$($MachineDefinitionFile.BaseName).log"
            $Definition['definition_file'] = $MachineDefinitionFile.FullName
            $Definition['group'] = $(Get-Item ($MachineDefinitionFile.PSParentPath)).BaseName
            $Definition['name'] = $MachineDefinitionFile.BaseName
            $Definition['extra_definitions'] = $ExtraDefinitions
            $Definition['SelfSame'] = $($MyMachineName -eq $Definition['name'])
            # Set Provider-Specific machine attributes
            if (Get-Command "$($Definition.vars.provider.type)`.set_attributes" -ErrorAction SilentlyContinue){
                $Definition = &"$($Definition.vars.provider.type)`.set_attributes" -MachineObj $Definition
            } else {
                Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.no_provider_attributes))) -debug
            }
            $MachineDefinitions += $Definition
        } catch {
            Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString error.failed_properties))) -err
            throw $_
        }
    }
    return $MachineDefinitions
}

Set-Alias -Name machine.definitions.get  -Value Get-MachineDefinitions 

Function machine.definitions.get.aio {
    Get-MachineDefinitions -MachineName $Settings.defaults.aio_machine_name
}