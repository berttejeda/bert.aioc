#region Scriptblocks
$Global:Logger = {
    if ($UILogger){
        if ($args[2] -eq "YesNo"){
            Invoke-Logger -Message $args[0] -Log $args[1] -GUI -YesNo
        } else {
            Invoke-Logger -Message $args[0] -Log $args[1] -GUI
        }
    } else {
        if ($args[2] -eq "YesNo") {
            Invoke-Logger -Message $args[0] -Log $args[1] -YesNo
        } else {
            Invoke-Logger -Message $args[0] -Log $args[1]
        }
    }
}
if (Get-Command Resolve-ErrorRecord -ErrorAction 'SilentlyContinue') {
    $Global:ErrLogger = {Invoke-Logger $(Resolve-ErrorRecord $args[0]),$args[1]}
} else{
    $Global:ErrLogger = {throw [System.Exception] $args[0]}
}
#endregion Scriptblocks

# -----------------------------------------------------------------------------
# Function 		: Invoke-Logger
# -----------------------------------------------------------------------------
# Description	: Outputs a string to the standard output as well as to a specified logfile
# Parameters    : 
# Returns       : Specified String
# Credits       : Bert Tejeda
# -----------------------------------------------------------------------------
function Invoke-Logger {
[cmdletbinding()]
Param (
    [parameter(ValueFromPipeline=$True,Position=0)][string[]]$Message,
    [parameter(ValueFromPipeline=$True,Position=1)]
    [Alias('Logs')]
    $Logfiles,
    [parameter(ValueFromPipeline=$False,Position=2)]
    $Color,
    [parameter(ValueFromPipeline=$False,Position=3)]
    $CallerObject,
    [parameter(ValueFromPipeline=$False,Position=4)]
    $MinimumLogLevel,
    [switch]$Info,
    [switch]$Warn,
    [switch]$Err,
    [switch]$GUI,
    [switch]$YesNo,
    [switch]$Pause,
    [switch]$i18n,
    [switch]$NoNewLine=$False
)
Begin {

    $DebugParameterIsPresent = $PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent
    $VerboseParameterIsPresent = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
    $GlobalVerboseIsOn = $Global:VerbosePreference -eq "Continue"
    $GlobalDebugIsOn = $Global:DebugPreference -eq "Continue"

    if (($VerboseParameterIsPresent -or $GlobalVerboseIsOn) -and $GlobalDebugIsOn){
        $DebugPreference = "Continue"
        Invoke-Command -ScriptBlock $Global:InvocationTrace
    } 

    switch ($True){
     ($DebugParameterIsPresent -and $GlobalDebugIsOn) {
        $DebugOn = $True
        $DebugPreference = "Continue"
        break
     }
     ($DebugParameterIsPresent -and !$GlobalDebugIsOn) {
        $DebugOn = $True
        $DebugPreference = "SilentlyContinue"
        break
     }
     default {break;}
    }

    Switch ($True) {
        ($Err)  { 
            If(!$Color){
                $Color = "Red"
            }
            If ($Message -notmatch "^Err"){
                $Message = "Error: " + "$Message" 
            }
            break
        }
        ($Warn)  { 
            If(!$Color){
                $Color = "Yellow"
            }
            If ($Message -notmatch "^Warn"){
                $Message = "Warning: " + "$Message" 
            }    
            break
        }
        ($Info)  { 
            If(!$Color){
                $Color = "Green"
            }
            If ($Message -notmatch "^Info"){
                $Message = "Info: " + "$Message" 
            }                     
            break
        }
        ($Debug)  { 
            If(!$Color){
                $Color = "Yellow"
            }
            break
        }
        default { 
            If(!$Color){
                $Color = "White"
            }
        }
    }


    if ($i18n){
        if (-not $CallerObject){
            if (Test-Path $MyInvocation.PSCommandPath){
                $CallerObject = Get-Item $MyInvocation.PSCommandPath
            } else {
                $CallerObject = $PSCommandPath
            }
        }
        $Message = $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString -CallerObject $CallerObject $Message)))
    }

    function MsgBox {
        param ($Message,$Title=$Script:ScriptTitle,$Buttons,$Icon,$DefaultButton="button1")
        return [System.Windows.Forms.MessageBox]::Show($Message,$Title,$Buttons,$Icon,$DefaultButton)
    }
}
Process {

    if ($MinimumLogLevel -and ($MinimumLogLevel -ne $Settings.logging.level)) {
        return
    }

    $TimeStamp = Get-Date

    If ($NoNewLine){
        If ($DebugOn){
            Write-Debug "$TimeStamp`:`t $Message"
        } Else {
            Write-Host -NoNewLine "$TimeStamp`:`t";Write-Host "$Message" -NoNewLine -ForegroundColor $Color -BackgroundColor Black
        }
    } Else {
        If ($DebugOn){
            Write-Debug "$TimeStamp`:`t $Message"
        } Else {
            Write-Host -NoNewLine "$TimeStamp`:`t";Write-Host "$Message" -ForegroundColor $Color -BackgroundColor Black
        }
    }
    ForEach($Logfile in $Logfiles) {
        Add-Content $Logfile "$TimeStamp`:`t$Message" -ErrorAction "SilentlyContinue"
    }
   #Check for UILogger Hook/Scriptblock in Calling Script
   #e.g. $Global:UILogger = {$barStatus.Text = $args[0]}
   #The UILogger must be declared in the Global scope and AFTER the objects to which it acts against
   if ($GUI) {
        if ($YesNo) {
            MsgBox -Message $Message -Buttons YESNO -Icon Information;
        }else{
            $UILogger.Invoke($Message)
        }        
    } elseif ($YesNo) {
        Read-Host $Message
   }
  
}
End {
    if ($pause) {
        &pause
    }
}
}
# End Function 		: Invoke-Logger

