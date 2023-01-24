function Get-BitBucketFile {

    [CmdletBinding()]             
    param ([Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True,Position=0)][Alias('user')]$UserName,
    [Parameter(Mandatory=$False,Position=1)]$Password,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials = [System.Management.Automation.PSCredential]::Empty,
    [Parameter(Mandatory=$True,Position=3)]$URL,
    [Parameter(Mandatory=$False,Position=4)]$OutFile
    )

    Invoke-Command -ScriptBlock $Global:InvocationTrace

    switch ($True) {
    ($Credentials.username -and $Credentials.password) {
        $Username = ($Credentials.GetNetworkCredential()).username
        $ClearPassword = ($Credentials.GetNetworkCredential()).password
        break;
    }
    (!$UserName) {$UserName = Read-Host "Enter your Bitbucket Username"}
    (!$Password) {
        $Password = Read-Host "Enter your Bitbucket Password" -AsSecureString
        $ClearPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    }
    ($Password -ne '') {$ClearPassword = $Password;break}
    default { break;}
    }
    $ClearCredentials = "$UserName`:$ClearPassword"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($ClearCredentials))
    $authorization = "Basic $encodedCredentials"
    $Headers = @{ 
        Authorization = $authorization 
        "Content-Type" = "application/json"
    }

    $RequestURL = "$URL/?raw"

    if ($OutFile){
        Invoke-WebRequest -Headers $Headers $RequestURL -OutFile $OutFile
    } else {
        return $(Invoke-WebRequest -Headers $Headers $RequestURL).content
    }
}
