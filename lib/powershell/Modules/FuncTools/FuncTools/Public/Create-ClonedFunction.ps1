function Create-ClonedFunction {
    param(
    [Parameter(Mandatory=$True,Position=0)]$FunctionName,
    [Parameter(Mandatory=$True,Position=1)]$NewFunctionName,
    [Parameter(Mandatory=$False,Position=2)]$Transformations,
    [switch]$CallDefaults
    )    

    if ($CallDefaults){
        $NewFunc = Copy-Command $FunctionName -NewName $NewFunctionName -CallDefaults
    } else {
        $NewFunc = Copy-Command $FunctionName -NewName $NewFunctionName
    }
    
    if ($Transformations){
        ForEach ($Transformation in $Transformations){
            [regex]$rx = $Transformation.pattern
            $NewFunc = $rx.Replace($NewFunc, $Transformation.replace_with)
        }
    }
    Invoke-Expression $NewFunc
}