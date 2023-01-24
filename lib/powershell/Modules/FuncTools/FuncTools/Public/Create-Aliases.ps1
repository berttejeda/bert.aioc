function Create-Aliases {
    $Settings.environment.cloned_functions = $Settings.environment.cloned_functions.split("`n") | Sort | Unique
    $ClonedFunctions = $Settings.environment.cloned_functions.split("`n") | Sort | Unique
    if ($ClonedFunctions.length -gt 0){
        ForEach ($ClonedFunction in $ClonedFunctions) {
            $ClonedFunctionData = $ClonedFunction.split(";")
            if (!$ClonedFunctionData){
                continue
            }
            if ($ClonedFunctionData.length -gt 2) {
                if ($ClonedFunctionData[2] -eq "CallDefaults") {
                    Create-ClonedFunction -FunctionName $ClonedFunctionData[0] -NewFunctionName $ClonedFunctionData[1] -CallDefaults -Transformations @(
                        @{"pattern" = 'Mandatory=\$true';"replace_with" = 'Mandatory=$false'},
                        @{"pattern" = '\[System.Object\]\$MachineEnvironment';"replace_with" = '[System.Object]$MachineEnvironment="{0}"' -f @($Settings.environment.default.path)},
                        @{"pattern" = '\[System.Object\]\$MachineName'; "replace_with" = '[System.Object]$MachineName="{0}"' -f $Settings.defaults.aiomachine}
                    )            
                }
            } else {
                Create-ClonedFunction -FunctionName $ClonedFunctionData[0] -NewFunctionName $ClonedFunctionData[1] -Transformations @(
                    @{"pattern" = '\[System.Object\]\$MachineEnvironment';"replace_with" = '[System.Object]$MachineEnvironment="{0}"' -f @($Settings.environment.default.path)}
                )
            }
        }

    }
}