Function Read-INI {
    #Read .ini file
    Get-Content $ConfigPath | Set-Variable ini -Scope $Scope
    #$Global:ini = Get-Content $ConfigPath
    #1st pass: Trim Spaces from Beginning
    $ini = $ini | ForEach-Object {$_.TrimStart()}
    #2nd pass: Set variables according to Key=Value pairs
    $ini | ForEach-Object {
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
    #4th pass: Set xml variables
    $iniXML = $($ini | Where-Object {$_[0] -NotMatch "^[[|#].*" -And $_[0] -Match "^[<].*"})
    if ($VerifyOnly)
    {
        try
        {
            [xml]"$XMLHeader$XMLBeg$iniXML$XMLEnd" | Set-Variable iniXML -Scope $Scope
            Return $True
        } catch
        { 
            Return $False
        }
    } else 
    {
        try
        {
            [xml]"$XMLHeader$XMLBeg$iniXML$XMLEnd" | Set-Variable iniXML -Scope $Scope
        } catch 
        {
            $ErrLogger.Invoke($_,$Log)
        }
    }
    #endregion ReadIni
    #region ReadSections
    [array]$ini | Select-String "^\[" | Set-Variable Sections -Scope $Scope
    $SectionCount = $Sections.Length
    if(!$Sections.Length){$Sections = $nSections=@($Sections);$SectionCount = 1}
    $start = {$Section=$Sections[$args[0]];$iniIndex=[array]::IndexOf($ini,"$Section");$iniIndex}
    $end = {$Section=$Sections[$args[0]+1];$iniIndex=[array]::IndexOf($ini,"$Section");$iniIndex}
    for ($i=0;$i -le $SectionCount -1;$i++){
    $start.Invoke($i) | Set-Variable s -Scope $Scope
    $end.Invoke($i) | Set-Variable e -Scope $Scope
    if($e -lt 0){
        $e = $ini.length-1
        $sLength = $s + ($e-$s + 1)
    }else{
        $e = $e - 1
        $sLength = $s + ($e-$s)
    }
    
   $SectionHeader = $ini[$s]
    
    if (!$iniSectionHeaders.Count)
    {
        $iniSectionHeaders += @($SectionHeader)
    } else 
    {
        if ($iniSectionHeaders -Contains($SectionHeader))
        {
            $Logger.Invoke("$ConfigPath`: Found Duplicate Section Header: $SectionHeader - Not Adding",$Log)
        } else
        {
            $iniSectionHeaders += @($SectionHeader)
        }
    }    
    
    $iniSectionHeaders | Set-Variable iniSectionHeaders -Scope $Scope
    #"Section is $SectionHeader,Start is: $s, end is: $e, sLength is: $sLength"
    #"Section $SectionHeader content is:"

    if (!$iniSections.Count)
    {
        $iniSections += @{"$SectionHeader"=$ini[$s..$sLength]}
    } else 
    {
        if ($iniSections.ContainsKey($SectionHeader))
        {
            $Logger.Invoke("$ConfigPath`: Found Duplicate Section: $_ - Not Adding",$Log)
        } else
        {
            $iniSections += @{"$SectionHeader"=$ini[$s..$sLength]}
        }
    }
    }
    #$iniSections | Set-Variable iniSections -Scope $Scope
    #"The first section of iniSections is $($iniSections[0])"
    #endregion ReadSections
    # Create a Hashtable with your output information
    $info = @{'ini'=$ini;'iniXML'=$iniXML;'iniSectionHeaders'=$iniSectionHeaders;'iniSections'=$iniSections}
    Write-Debug (New-Object –Typename PSObject –Prop $info)    
}