[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$Port,
    [switch]$PassThru
)

if ($PSBoundParameters.ContainsKey('Debug')) {
    $Script:DebugPreference = 'Continue'
}
  
$listener = [System.Net.Sockets.TcpListener]::new($port)

try {
    $listener.Start()
    Write-Host "Listening on port $port..."

    while ($true) {
        if ($listener.Pending()) {
            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream)

            while ($client.Connected -and $stream.DataAvailable) {
                $data = $reader.ReadLine()
                if ($data) {
                    Write-Host "Received: $data"
                    if ($PassThru) {
                        $data
                    }
                }
            }

            Write-Debug "Closing reader, stream, client."
            $reader.Close()
            $stream.Close()
            $client.Close()
            if ($PassThru) {
                Write-Debug "PassThru mode: Connection closed. Exiting."
                Break
            }
        }
        Start-Sleep -Milliseconds 100
    }
}
finally {
    Write-Host "`nStopping listener..."
    $listener.Stop()
}
