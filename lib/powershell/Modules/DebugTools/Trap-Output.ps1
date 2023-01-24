function TrapOut {

# TrapOut gets the date, gets the error message, and adds this to an error.log

$timeOfError  = (get-date).DateTime
$lineNumber   = $_.InvocationInfo.ScriptLineNumber
$offsetInLine = $_.InvocationInfo.OffsetInLine
$errorMessage = $_.Exception.Message

""
"TIME: LINE.CHARACTER :ERROR"
"==========================="
$timeOfError + ": " + $lineNumber + "." + $offsetInLine + " :" + $errorMessage
$timeOfError + ": " + $lineNumber + "." + $offsetInLine + " :" + $errorMessage >> error.log

# The following output simply displays what is available from an exception
""
"EXCEPTION gm (get-members)"
"=========================="
$_.Exception | Get-Member
""
"PROPERTIES OF THE EXCEPTION'S Exception"
"======================================="
"CommandName                 :" + $_.Exception.CommandName
"Data                        :" + $_.Exception.Data
"ErrorRecord                 :" + $_.Exception.ErrorRecord
"HelpLink                    :" + $_.Exception.HelpLink
"InnerException              :" + $_.Exception.InnerException
"Message                     :" + $_.Exception.Message
"Source                      :" + $_.Exception.Source
"StackTrace                  :" + $_.Exception.StackTrace
"TargetSite                  :" + $_.Exception.TargetSite
"WasThrownFromThrowStatement :" + $_.Exception.WasThrownFromThrowStatement
""
"INVOCATION INFO gm (get-members)"
"================================"
$_.InvocationInfo | Get-Member
""
"PROPERTIES OF THE EXCEPTION'S InvocationInfo"
"============================================"
"BoundParameters       :" + $_.InvocationInfo.BoundParameters
"CommandOrigin         :" + $_.InvocationInfo.CommandOrigin
"DisplayScriptPosition :" + $_.InvocationInfo.DisplayScriptPosition
"ExpectingInput        :" + $_.InvocationInfo.ExpectingInput
"HistoryId             :" + $_.InvocationInfo.HistoryId
"InvocationName        :" + $_.InvocationInfo.InvocationName
"Line                  :" + $_.InvocationInfo.Line
"MyCommand             :" + $_.InvocationInfo.MyCommand
"OffsetInLine          :" + $_.InvocationInfo.OffsetInLine
"PipelineLength        :" + $_.InvocationInfo.PipelineLength
"PipelinePosition      :" + $_.InvocationInfo.PipelinePosition
"PositionMessage       :" + $_.InvocationInfo.PositionMessage
"PSCommandPath         :" + $_.InvocationInfo.PSCommandPath
"PSScriptRoot          :" + $_.InvocationInfo.PSScriptRoot
"ScriptLineNumber      :" + $_.InvocationInfo.ScriptLineNumber
"ScriptName            :" + $_.InvocationInfo.ScriptName
"UnboundArguments      :" + $_.InvocationInfo.UnboundArguments
""

}