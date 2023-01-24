function Test-TCPConnection {

  param(
  [Parameter(Mandatory=$True,Position=0)]$hostname,
  [Parameter(Mandatory=$False,Position=1)]$port,
  [Parameter(Mandatory=$False,Position=2)]$timeout=5
  )

  $requestCallback = $state = $null
  $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect($hostname,$port,$requestCallback,$state)
  Start-Sleep -milli $timeOut
  if ($client.Connected) { 
      $connected = $True 
  } else { 
      $connected = $False 
  }
  $client.Close()
  return $connected
}