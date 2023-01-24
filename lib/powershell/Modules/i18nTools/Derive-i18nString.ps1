function Derive-i18nString {

    Param (
        [parameter(ValueFromPipeline=$True,Position=0)]
        $Message,
        [parameter(ValueFromPipeline=$False,Position=1)]
        $i18nRoot="settings",
        [parameter(ValueFromPipeline=$False,Position=2)]
        $Locale=$settings.defaults.locale,
        [parameter(ValueFromPipeline=$False,Position=3)]
        $CallerObject=$(Get-Item $MyInvocation.PSCommandPath)
    )  

    Invoke-Command -ScriptBlock $Global:InvocationTrace  
    
    Invoke-Logger "CallerObject is $CallerObject" -debug -MinimumLogLevel 2
    $CallerRoot = (Split-Path $CallerObject.Directory -Leaf) -Replace('-|_','')
    Invoke-Logger "CallerRoot is $CallerRoot" -debug -MinimumLogLevel 2
    $CallerName = $CallerObject.BaseName
    Invoke-Logger "CallerName is $CallerName" -debug -MinimumLogLevel 2
    $MessagePointer = "`$$i18nRoot.i18n.$Locale.$CallerRoot.`"$($CallerName)`".$Message"
    Invoke-Logger "Message pointer is $MessagePointer" -debug -MinimumLogLevel 2
    $Message = Invoke-Expression $MessagePointer
    Invoke-Logger "Derived Message is $Message" -debug -MinimumLogLevel 2
    return $Message
}

Set-Alias -Name i18n.derive -Value Derive-i18nString
