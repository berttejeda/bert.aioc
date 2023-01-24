param(
    [Parameter(
    Mandatory=$false, 
    Position=0, 
    ValueFromPipeline=$true,
    HelpMessage='Specify the subject string filter for exporting the certs'
    )]$bySubject,

    [Parameter(
    Mandatory=$false, 
    Position=1, 
    ValueFromPipeline=$true,
    HelpMessage='Specify destination directory for the exported certs'
    )]$dest="C:\temp",
    
    [Parameter(
    Mandatory=$false, 
    Position=2, 
    ValueFromPipeline=$true,
    HelpMessage='If specified file exists in destination, abort'
    )]$checkfile,
    [Switch]$list_certs=$False
)

If ($checkfile){
    If ((Test-Path $checkfile)) {
        Exit;
    } 
}

If ( -NOT (Test-Path "$($dest)") ) {
    Try {
        New-Item -ItemType Directory -Path "$($dest)"
    } Catch {
        "Couldn't create $($dest) due to error: $($_.Exception.Message)"
    }
}

$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$cert_type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
$stores = @("Root", "CA")
ForEach($store in $stores){
    If ($bySubject) {
        $certs = $(get-childitem -path cert:\LocalMachine\$store | Where-Object { $_.Subject -match "$($bySubject)" } )
    }ELSE{
        $certs = get-childitem -path cert:\LocalMachine\$store
    }
    ForEach($cert in $certs){
        if ($list_certs){
            """Cert: 
                Subject:$($cert.Subject)"""
            continue
        }
        "Exporting cert with subject $($cert.Subject) to $dest"
        $CertSubject = $cert.Subject.ToString().split('|=, ') -Join('_') -Replace('__','_')
        $DestCertName = '{0}.{1}' -f $CertSubject,[System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($CertSubject)))
        $DestCertPath = Join-Path $dest "$($DestCertName).cer"
        "Writing $DestCertPath"
        Try {
            [System.IO.File]::WriteAllBytes($DestCertPath, $cert.export($cert_type) ) 
        } Catch {
            "Couldn't write $($dest) due to error: $($_.Exception.Message)"
        }    

    }
}