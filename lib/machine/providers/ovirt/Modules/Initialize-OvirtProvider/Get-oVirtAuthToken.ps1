<#
.Synopsis
   Obtains oVirt authorization token for use in further commandlets
.DESCRIPTION
   Obtains oVirt authorization token for use in further commandlets, this token will expire depending on your oVirt server settings
.EXAMPLE
    The following example authenticates to the oVirt server using the default built-in username and domain admin@internal
    $oVirtSvr = 'ovirt-server.domain.local'
    Get-oVirtAuthToken -oVirtServerName $oVirtSvr -oVirtPassword 'password'
.EXAMPLE
   The following example authenticates to the oVirt server using the username and domain MyUser@mydomain.local
    Get-oVirtAuthToken -oVirtServerName "ovirt-server.domain.local" -oVirtUser 'MyUser' -oVirtPassword 'password' -oVirtDomain 'mydomain.local'
#>
function Get-oVirtAuthToken
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        #Address of oVirt server (must be FQDN)
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $oVirtServerName,

        #Username for oVirt (admin is default)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        $oVirtUsername = 'admin',

        #Password for the oVirt user to authenticate as
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        $oVirtPassword,

        #domain the oVirt user belongs to (default is internal)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        $oVirtDomain = 'internal',
        
        #Wether or not to trust the remote certificate
        [switch][Alias('k')]
        $SkipCertificateCheck
    )
        $AuthPayload = "grant_type=password&scope=ovirt-app-api&username=$oVirtUsername%40$oVirtDomain&password=$oVirtPassword"
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.auth.payload))) -debug
        $AuthHeaders = @{"Accept" = "application/json"}
        $URI = "https://$oVirtServerName/ovirt-engine/sso/oauth/token"
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.auth.uri))) -debug
        if ($SkipCertificateCheck){
            $AuthResponse = Invoke-WebRequest -Uri $URI -Method Post -body $AuthPayload -Headers $AuthHeaders -ContentType 'application/x-www-form-urlencoded' -SkipCertificateCheck
        } else {
            $AuthResponse = Invoke-WebRequest -Uri $URI -Method Post -body $AuthPayload -Headers $AuthHeaders -ContentType 'application/x-www-form-urlencoded'
        }
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.auth.response))) -debug
        $AuthToken = ((($AuthResponse.Content) -split '"')[3])
        Invoke-Logger $($ExecutionContext.InvokeCommand.ExpandString($(Derive-i18nString info.auth.token))) -debug
        return $AuthToken
}