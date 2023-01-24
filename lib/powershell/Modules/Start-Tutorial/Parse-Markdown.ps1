Function Parse-Markdown{
    param(
    [Parameter(Mandatory=$False,ValueFromPipeline,Position=0)]$InputString   
    )    
    If ($InputString) {
        try{
            $ErrorActionPreference = "SilentlyContinue"
            $OutputString = $InputString | Show-Markdown
        } catch {
            $OutputString = $InputString
            Write-Warning "Failed to process markdown for input string"
        }
    } Else {
            $OutputString = ""
   }
   return $OutputString
}