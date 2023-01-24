Function Read-YAML {
    $private:vars = ConvertFrom-Yaml -Path $ConfigPath
    #1st pass: Set variables according to Key=Value pairs
    $vars | ForEach-Object {
        $k = $_ -Split "=",2
        if ($k[0] -NotMatch "^[[|#|\s|<].*" -and $k[1] -ne $null -and $k[1] -ne "") 
        { 
            if ($k[1] -ne $null -and "$($k[1])" -ne "") 
            { 
                if (!$(Get-Variable -Name $k[0] -ErrorAction SilentlyContinue))
                {
                    Invoke-Expression("""$($k[1])"" | Set-Variable ""$($k[0])"" -Scope $Scope")
                } else
                {
                    $ExistingVariable = (Get-Variable -Name $k[0]).Value
                    $Logger.Invoke("$ConfigPath`: Found conflicting variable: $($k[0]) - Not Overwriting Existing Value $ExistingVariable",$Log)
                }
            } 
        } 
    }
    #3rd pass: Convert Bool-type variables to Boolean values (variable names must begin with "Bool")
    $ini | ForEach-Object {
        $b = $_ -Split "=",2
        if ($b[0]-NotMatch "^[[|#|\s|<].*" -And $b[0] -Match "^Bool") 
        {
            if (!$(Get-Variable -Name $b[0] -ErrorAction SilentlyContinue)){
                [System.Convert]::ToBoolean($b[1]) | Set-Variable $b[0] -Scope $Scope
            } 
        } 
    }    
}