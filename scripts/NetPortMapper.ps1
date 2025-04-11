[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$ListenPort,
    [Parameter(Mandatory = $true)][string]$RemoteHost,
    [Parameter(Mandatory = $true)][int]$RemotePort
)

if ($PSBoundParameters.ContainsKey('Debug')) {
    $Script:DebugPreference = 'Continue'
}

$listener = [System.Net.Sockets.TcpListener]::new($ListenPort)

try {
    $listener.Start()
    Write-Host "Listening on port $ListenPort → ${RemoteHost}:$RemotePort"

    while ($true) {
        Write-Verbose "Waiting for connection...: `$Listener.Pending(): $($listener.Pending())"

        if ($listener.Pending()) {
            $client = $listener.AcceptTcpClient()
            Write-Host "Accepted connection from $($client.Client.RemoteEndPoint)"

            $remote = [System.Net.Sockets.TcpClient]::new()
            $remote.Connect($RemoteHost, $RemotePort)
            Write-Host "Connected to ${RemoteHost}:$RemotePort"

            $clientStream = $client.GetStream()
            $remoteStream = $remote.GetStream()

            $clientStream.ReadTimeout = 100
            $remoteStream.ReadTimeout = 100
            $buffer = New-Object byte[] 8192

            while ($true) {
                if ($listener.Pending()) {
                    Write-Debug "Connections are pending."
                }

                $DataReceived = $false
                try {
                    Write-Verbose "Checking for client data.."
                    $count = $clientStream.Read($buffer, 0, $buffer.Length)
                    if ($count -eq 0) {
                        Write-Debug "C→R: client closed stream"
                        break
                    }
                    $DataReceived = $true
                    Write-Debug "C→R: $count bytes"
                    # $data = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $count); Write-Verbose "C→R: $data"
                    $remoteStream.Write($buffer, 0, $count)
                    $remoteStream.Flush()
                }
                catch [System.IO.IOException] {
                    # Timeout, ignore
                }

                try {
                    $count = $remoteStream.Read($buffer, 0, $buffer.Length)
                    if ($count -eq 0) {
                        Write-Debug "R→C: remote closed stream"
                        break
                    }
                    $DataReceived = $true
                    Write-Debug "R→C: $count bytes"
                    # $data = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $count); Write-Verbose "R→C: $data"

                    $clientStream.Write($buffer, 0, $count)
                    $clientStream.Flush()
                }
                catch [System.IO.IOException] {
                    # Timeout, ignore
                }

                if (-not $DataReceived) {
                    Write-Verbose "C↔R: Connection idle, no data.."
                }
                Start-Sleep -Milliseconds 50
            }

            Write-Host "Closing connection..."
            $clientStream.Close()
            $remoteStream.Close()
            $client.Close()
            $remote.Close()
        }
        Start-Sleep -Milliseconds 500
    }
}
finally {
    Write-Host "`nStopping listener..."
    $listener.Stop()
}

