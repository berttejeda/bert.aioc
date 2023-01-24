# Clear-Host, Without Clearing the Host - tommymaynard.com
# https://tommymaynard.com/clear-host-without-clearing-the-host-2014/
Function SafelyClear-Host($SaveRows) {
    If ($SaveRows) {
        try{
            [System.Console]::SetWindowPosition(0,[System.Console]::CursorTop-($SaveRows+1))

        } catch {
        }
    } Else {
        try{
            [System.Console]::SetWindowPosition(0,[System.Console]::CursorTop)
        } catch {
        }
   }
}