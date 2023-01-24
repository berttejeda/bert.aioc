function Test-NetPort {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [String] $ComputerName,

        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [Int] $Port,

        [Int] $Timeout = 2
    )

    process {
        $TCPConnect = New-Object -TypeName System.Net.Sockets.TcpClient
        Write-Verbose -Message "Attempting connection to computer: $ComputerName on TCP port: $Port"
        try {
            $TCPConnect.ConnectAsync($ComputerName,$Port).Wait([timespan]::FromSeconds($Timeout))
        } catch [ArgumentOutOfRangeException] {
            Write-Error -Message 'Port defined was out of range' -ErrorAction Continue
            return $False
        } catch [AggregateException] {
            Write-Debug -Message $_.Exception.InnerException.Message
            return $False
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Continue
        } finally {
            $TCPConnect.Dispose()
        }
    }
}