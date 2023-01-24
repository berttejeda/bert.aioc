Function Start-Tutorial {
    param(
    [Parameter(Mandatory=$True,Position=0)]$TutorialObj,
    [Parameter(Mandatory=$False,Position=1)]$Username,
    [Parameter(Mandatory=$False,Position=2)]$Password,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials = [System.Management.Automation.PSCredential]::Empty,
    [switch]$all,
    [switch]$FromBitBucket,
    [switch]$nopause
    )

    if (Get-Command Show-Markdown -ErrorAction SilentlyContinue){
        $MarkDownEnabled = $True
    } else {
        $MarkDownEnabled = $False
    }
    SafelyClear-Host

    if ($all){
        ForEach ($Td in $(Get-ChildItem $TutorialObj | Sort-Object)){
            SafelyClear-Host
            Write-Host "Commencing Tutorial Set $Td"
            Start-Tutorial -TutorialsDir "$($Td.Fullname)"
            Write-Host "Tutorial Set $Td End" -ForegroundColor Cyan -BackgroundColor Black
            if (!$nopause){
                Write-Host "Press Enter to proceed to the next Tutorial Set ..." -ForegroundColor Cyan -BackgroundColor Black
                Read-Host
            }
        }
        Write-Host "No more Tutorial Sets to process"
    } else {

        if ($TutorialObj -match '^http'){
            $TutorialSets += @($TutorialObj)
        } else {
            $TutorialSets = Get-ChildItem -Path $TutorialObj | Sort-Object
        }

        $Patterns = New-Object PSObject -Property @{
          'ExpandString' = '(.*)<%= (.*) %>(.*)';
          'PauseTutorial' = '^\{&pause\}$';
          'TutorialName' = '<!-- (.*) -->';
          'HTTPFile' = '^(http|https)';
          'InlineCredentials' = '(http|https)([\W]+)([\w]+):([\w]+)(@.*)';
        }

        ForEach ($TutorialSet in $TutorialSets) {
            switch ($True) {
             ($TutorialSet -match $Patterns.HTTPFile) {
                if ($FromBitBucket) {
                    switch ($True) {
                    ($TutorialSet -match $Patterns.InlineCredentials) {
                        $MatchedObject = [regex]::Match($TutorialSet,$Patterns.InlineCredentials)
                        $Username = $MatchedObject.captures.groups[3].value
                        $ClearPassword = $MatchedObject.captures.groups[4].value
                        break
                    }
                    ($Credentials.username -and $Credentials.password) {
                        $Username = ($Credentials.GetNetworkCredential()).username
                        $ClearPassword = ($Credentials.GetNetworkCredential()).password
                        break
                    }
                    (!$UserName) {$UserName = Read-Host "Enter your Bitbucket Username"}
                    (!$Password) {
                        $Password = Read-Host "Enter your Bitbucket Password" -AsSecureString
                        $ClearPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
                        break
                    }
                    default { break;}
                    }                    
                    try {
                        $TutorialContent = $(Get-BitBucketFile -URL $TutorialSet -Username $Username -Password $ClearPassword).split("`n")
                    } catch {
                        
                        if ($DebugPreference -ne "Continue"){
                            Write-Warning "Error downloading Tutorial Content, call function again with -debug switch for more information"
                        } elseif ($DebugPreference -eq "Continue") {
                            Parse-TutorialException "" $_
                        }

                        return
                    }
                } else {
                    try {
                        $TutorialContent = (New-Object Net.WebClient).downloadstring($TutorialSet).split("`n")
                    } catch {

                        if ($DebugPreference -ne "Continue"){
                            Write-Warning "Error downloading Tutorial Content, call function again with -debug switch for more information"
                        } elseif ($DebugPreference -eq "Continue") {
                            Parse-TutorialException "" $_
                        }    

                        return

                    }
                }
                
                try {
                    $TutorialContent = $TutorialContent.split("`n")
                } catch {
                    Write-Warning "Error parsing Tutorial Content - $TutorialObj"
                    return
                }
                $TutorialName = $TutorialObj.split('/')[-1]
                break           

             }

            (Test-Path $TutorialSet) {
                if ($TutorialSet -is [System.IO.DirectoryInfo]) {
                Write-Warning "You must specify either a directory containing lab files (.md) or a lab file directly"
                return 
                }
                $TutorialContent = Get-Content $TutorialSet.FullName -Encoding UTF8
                $TutorialName = $($TutorialSet.BaseName)
            }
             default { continue }
            }

            if ($TutorialContent.length -eq 0){
                Write-Error "$TutorialObj appears to be an empty file"
                return
            }

            if ($TutorialContent[0] -match $Patterns.TutorialName) {
                $MatchedObject = [regex]::Match($TutorialContent[0],$Patterns.TutorialName)
                $MatchedString = $MatchedObject.captures.groups[1].value
                $MatchedStringExpanded = Expand-String $MatchedString
                $TutorialName = $MatchedStringExpanded
                $TutorialContent = $TutorialContent | Select-Object -Skip 1
            }

            # Append the congratulatory exercise to the content
            $TutorialContent += "## Pat yourself on the back, you're done!"

            # Initialize variables
            $LabPrompt = $NULL

            try {
                $TutorialContentUpperBoundary = $TutorialContent.GetUpperBound(0)
                $TutorialHeaders = $TutorialContent | Select-String -Pattern '^[#]{1}.*'
                $HeaderLineIndices = $TutorialHeaders | Select-Object -ExpandProperty LineNumber | ForEach-Object { [math]::max(0, $_ -1) }
                
                $OuterIndex = 0 # Header Index
                $StepNum = 1 # Init Step Number
                $ExerciseNum = 1 # Init Exercise Number

                $MainLineIndex = 0
                $MainHeaderLineIndices = $HeaderLineIndices | Where-Object { $TutorialContent[$_] -Match '^# ' }
                $ExerciseLineIndex = 0
                $ExerciseLineIndices = $HeaderLineIndices | Where-Object { $TutorialContent[$_] -Match '^## ' }
                $MultiPartExerciseLineTracker = @{}
                $HeaderLineIndices | Where-Object { $TutorialContent[$_] -Match '^## ' } | %{$TutorialContent[$_] } | ForEach-Object {$MultiPartExerciseLineTracker["$_"] += 1} | Sort-Object
                $MultiPartExercises = $MultiPartExerciseLineTracker.keys | Where-Object { $MultiPartExerciseLineTracker["$_"] -gt 1 } | ForEach-Object { $_ }

                $StepLineIndex = 0
                $StepLineIndices = $HeaderLineIndices | Where-Object { $TutorialContent[$_] -Match '^### ' }
                $MultiPartStepLineTracker = @{}
                $HeaderLineIndices | Where-Object { $TutorialContent[$_] -Match '^### ' } | %{$TutorialContent[$_] } | ForEach-Object {$MultiPartStepLineTracker["$_"] += 1} | Sort-Object
                $MultiPartSteps = $MultiPartStepLineTracker.keys | Where-Object { $MultiPartStepLineTracker["$_"] -gt 1 } | ForEach-Object { $_ }
            } catch {

                if ($DebugPreference -ne "Continue"){
                    Write-Warning "I encountered a problem when initializing the specified tutorial - $TutorialObj, call function again with -debug switch for more information"
                } elseif ($DebugPreference -eq "Continue") {
                    Parse-TutorialException "" $_
                }  
                
                return
                
            }


            :inner ForEach ($HeaderLineIndex in $HeaderLineIndices) {

                $Content = ""

                Write-Debug "Current OuterIndex: $OuterIndex"
                Write-Debug "Current HeaderLineIndex: $CurrentHeaderLineIndex"
                Write-Debug "Current ExerciseLineIndex: $ExerciseLineIndex"
                Write-Debug "Current StepLineIndex: $StepLineIndex"

                Write-Debug "MultiPartExercises: $MultiPartExercises"
                Write-Debug "MultiPartSteps: $MultiPartSteps"                

                $HeaderLine = $TutorialContent | Select -Index ($HeaderLineIndex)

                Write-Debug "CurrentHeaderLine: $HeaderLine"

                if ($OuterIndex -1 -lt 0){
                    $SectionStart = $OuterIndex
                    $SectionEnd = $HeaderLineIndices[$HeaderLineIndex]
                } else {
                    $SectionStart = $HeaderLineIndex
                    $SectionEnd = $HeaderLineIndices[$OuterIndex+1] - 2
                }
                if ($SectionEnd -lt 0){
                    $SectionEnd = $SectionStart
                }

                Write-Debug "SectionStart File Line Number: $($SectionStart +1)"
                Write-Debug "SectionEnd   File Line Number: $($SectionEnd +1)"                
                
                ForEach ($l in $TutorialContent[$SectionStart..$SectionEnd].split('`n')){
                    switch ($True){
                        ($l -Match $Patterns.ExpandString) {
                            try {
                                $MatchedObject = [regex]::Match($l,$Patterns.ExpandString)
                                $PreMatch = $MatchedObject.captures.groups[1].value
                                $MatchedString = $MatchedObject.captures.groups[2].value
                                $MatchedStringExpanded = Expand-String $MatchedString
                                $PostMatch = $MatchedObject.captures.groups[3].value
                                $l = $PreMatch + $MatchedStringExpanded + $PostMatch
                            } catch {
                                Write-Debug "Failed to expand input string ($l)"
                            }
                        }
                        ($l -Match $Patterns.PauseTutorial) { 
                            Write-Host 'Press Enter to proceed ...' -ForegroundColor Cyan -BackgroundColor Black
                            $LabPrompt = Read-Host
                            SafelyClear-Host
                            $l = $l.replace($l, '') 
                        }
                        default { break; }

                    }
                    $Content += $($l -Replace('<br />|<br> <br >', "`n`n")) + "`n"
                } 
                if ([console]::WindowHeight -lt $Content.split("`n").length+2 -and !$nopause){
                    $Paginate = $True
                } else {
                    $Paginate = $False
                }
                if ($HeaderLineIndex -in $MainHeaderLineIndices) { 
                    $IsMainHeader = $True 
                } else {
                    $IsMainHeader = $False 
                }
                if ($HeaderLineIndex -in $ExerciseLineIndices) { 
                    $IsExercise = $True 
                } else {
                    $IsExercise = $False 
                }

                Write-Debug "IsExercise?: $IsExercise"

                if ($HeaderLineIndex -in $StepLineIndices) { 
                    $IsStep = $True 
                } else {
                    $IsStep = $False 
                } 

                Write-Debug "IsStep?: $IsStep"

                if ($HeaderLine -in $MultiPartExercises) { 
                    $IsMultiPartExercise = $True 
                } else {
                    $IsMultiPartExercise = $False 
                }

                Write-Debug "IsMultiPartExercise?: $IsMultiPartExercise"

                if ($HeaderLine -in $MultiPartSteps) { 
                    $IsMultiPartStep = $True 
                } else {
                    $IsMultiPartStep = $False 
                }         

                Write-Debug "IsMultiPartStep?: $IsMultiPartStep"

                $CurrentHeaderLineIndex = $($HeaderLineIndices[$OuterIndex])
                
                Write-Debug "TutorialContentUpperBoundary = $TutorialContentUpperBoundary"
                Write-Debug "TutorialContentLength = $($TutorialContent.length)"

                # Tracking previous/next exercise line headers
                # This is for bullet-proofing exercise numbering
                $PreviousExerciseLineArrayValue = $ExerciseLineIndices[[math]::max(0, $ExerciseLineIndex-1)]
                $CurrentExerciseLineArrayValue = $ExerciseLineIndices[$ExerciseLineIndex]
                try{
                    $NextExerciseLineArrayValue = $ExerciseLineIndices[$ExerciseLineIndex+1]
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }
                }
                Write-Debug "Current ExerciseLineArrayValue: $CurrentExerciseLineArrayValue"
                Write-Debug "PreviousExerciseLineArrayValue: $PreviousExerciseLineArrayValue"                
                Write-Debug "NextExerciseLineArrayValue: $NextExerciseLineArrayValue"                

                try {
                    $CurrentExerciseHeaderLine = $TutorialContent[$CurrentExerciseLineArrayValue].Trim()
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }                    
                }

                Write-Debug "CurrentExerciseHeaderLine: $CurrentExerciseHeaderLine ($($CurrentExerciseHeaderLine.length) characters long)"

                try{
                    $PreviousExerciseHeaderLine = $TutorialContent[$PreviousExerciseLineArrayValue].Trim()
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }                    
                }

                try{
                    $NextExerciseHeaderLine = $TutorialContent[$NextExerciseLineArrayValue].Trim()
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }                    
                }     

                Write-Debug "PreviousExerciseHeaderLine: $PreviousExerciseHeaderLine ($($PreviousExerciseHeaderLine.length) characters long)"
                Write-Debug "NextExerciseHeaderLine: $NextExerciseHeaderLine ($($NextExerciseHeaderLine.length) characters long)"

                $PreviousExerciseLineIsEqual = $HeaderLine -eq $PreviousExerciseHeaderLine
                $NextExerciseHeaderLineIsEqual = $HeaderLine -eq $NextExerciseHeaderLine

                Write-Debug "CurrentExerciseHeaderLine -eq PreviousExerciseHeaderLine?: $PreviousExerciseLineIsEqual"
                Write-Debug "CurrentExerciseHeaderLine -eq NextExerciseHeaderLine?: $NextExerciseHeaderLineIsEqual"

                # Tracking previous/next step line headers
                # This is for bullet-proofing step numbering
                try{
                    $PreviousStepLineArrayValue = $StepLineIndices[[math]::max(0, $StepLineIndex-1)]
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }                    
                }
                try{
                    $CurrentStepLineArrayValue = $StepLineIndices[$StepLineIndex]
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }                    
                }                
                try{
                    $NextStepLineArrayValue = $StepLineIndices[$StepLineIndex+1]
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }                    
                }
                try{
                    $PreviousStepHeaderLine = $TutorialContent[$PreviousStepLineArrayValue]
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }                    
                }                
                try {
                    $CurrentStepHeaderLine = $TutorialContent[$CurrentStepLineArrayValue]
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }
                }                

                Write-Debug "CurrentStepHeaderLine: $CurrentStepHeaderLine ($($CurrentStepHeaderLine.length) characters long)"
                Write-Debug "PreviousStepHeaderLine: $PreviousStepHeaderLine ($($PreviousStepHeaderLine.length) characters long)"

                try {
                    $NextStepHeaderLine = $TutorialContent[$NextStepLineArrayValue]
                } catch {
                    if ($DebugPreference -eq "Continue"){
                        Parse-TutorialException "Encountered a possible array boundary" $_
                    }
                }
                Write-Debug "NextStepHeaderLine: $NextStepHeaderLine ($($NextStepHeaderLine.length) characters long)"

                $PreviousStepLineIsEqual = $HeaderLine -eq $PreviousStepHeaderLine
                $NextStepHeaderLineIsEqual = $HeaderLine -eq $NextStepHeaderLine

                Write-Debug "CurrentStepHeaderLine -eq PreviousStepHeaderLine?: $PreviousStepLineIsEqual"
                Write-Debug "CurrentStepHeaderLine -eq NextStepHeaderLine?: $NextStepHeaderLineIsEqual"
                
                Switch ($True) {             

                   ($HeaderLineIndex -in $MainHeaderLineIndices)  {

                        if ($MarkDownEnabled){
                            Parse-Markdown $Content
                        } else {
                            $Content
                        }
                   }

                   ($HeaderLineIndex -in $ExerciseLineIndices)  { 

                        $StepNum = 1
                        $ExerciseDesignation = "{0:D2}" -f $ExerciseNum
                        $Content = $Content -Replace('^##',"## Exercise-$ExerciseDesignation`: ")
                        Switch ($True) {
                           ($MarkDownEnabled -and $Paginate)  { Parse-Markdown $Content;break }
                           ($MarkDownEnabled)  { Parse-Markdown $Content;break }
                           default { $Content }
                        } 
                        if (!$nopause){
                            Write-Host 'Press Enter to proceed ...' -ForegroundColor Cyan -BackgroundColor Black
                            Write-Host 'Enter N to skip to the next exercise ...' -ForegroundColor DarkGray -BackgroundColor Black
                            $LabPrompt = Read-Host
                            if ($LabPrompt.tolower() -eq 'n'){
                                $NextExerciseHeaderLineIndex = $($ExerciseLineIndices[$ExerciseLineIndex+1])
                            } else {
                                $NextExerciseHeaderLineIndex = $NULL
                            }
                            SafelyClear-Host
                        }

                        Write-Debug "-not `$IsMultiPartExercise: $(-not $IsMultiPartExercise)"
                        
                        # Increment exercise number
                        if ((-not $IsMainHeader -and -not $IsMultiPartExercise) -or !$NextExerciseHeaderLineIsEqual){
                            Write-Debug "Incrementing exercise number"
                            $ExerciseNum++
                        }

                        $ExerciseLineIndex++

                   }

                   ($HeaderLineIndex -in $StepLineIndices)  {

                        $StepDesignation = "{0:D2}" -f $StepNum
                        $Content = $Content -Replace('^###',"### Step $StepDesignation $StepSuffix - ")
                        
                        # Skip Step Contents if we've chosen to skip the exercise
                        if ($NextExerciseHeaderLineIndex -and $HeaderLineIndex -lt $NextExerciseHeaderLineIndex){
                            $StepLineIndex++
                            continue
                        }        

                        Switch ($True) {
                           ($MarkDownEnabled -and $Paginate)  { 
                            Write-Warning "The following section is larger than the terminal window size`nConsider breaking it up into multi-part steps and/or Exercises"
                            $ChoppedContent = $Content.split("`n")
                            Parse-Markdown $ChoppedContent[0]
                            Write-Host 'Press Enter to proceed ...' -ForegroundColor Cyan -BackgroundColor Black
                            Read-Host
                            SafelyClear-Host
                            Parse-Markdown $($ChoppedContent | Select -Skip 1 | Out-String)
                            break 
                           }
                           ($MarkDownEnabled)  { Parse-Markdown $Content;break }
                           default { $Content }
                        }
                        if (!$nopause){
                            Write-Host 'Press Enter to proceed to the next step ...' -ForegroundColor Cyan -BackgroundColor Black
                            $LabPrompt = Read-Host
                            SafelyClear-Host
                        }

                        Write-Debug "-not `$IsMultiPartStep: $(-not $IsMultiPartStep)"
                        
                        # Increment step number
                        if ((-not $IsMainHeader -and -not $IsMultiPartStep) -or !$NextStepHeaderLineIsEqual){
                            Write-Debug "Incrementing step number"
                            $StepNum++                    
                        }
                        $StepLineIndex++                                  
                   }

                   default { continue }

                } 

                if ($HeaderLineIndex -eq $HeaderLineIndices[-1]){
                    Write-Host "Tutorial Complete - $TutorialName"
                    return   
                }

            $OuterIndex++

            }

            $ExerciseNum = 0

        }
    }
}

Function tutorial.list {
    param(
    [Parameter(Mandatory=$False,Position=0)]$TutorialDir="$PWD\tutorials"
    )    
    Get-ChildItem "$TutorialDir" | Sort-Object
}


Set-Alias -Name tutorial.start -Value Start-Tutorial