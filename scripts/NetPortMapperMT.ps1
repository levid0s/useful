[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$ListenPort,
    [Parameter(Mandatory = $true)][string]$RemoteHost,
    [Parameter(Mandatory = $true)][int]$RemotePort
)

if ($PSBoundParameters.ContainsKey('Debug')) {
    $Script:DebugPreference = 'Continue'
}

Import-Module ThreadJob
$listener = [System.Net.Sockets.TcpListener]::new($ListenPort)
$global:allJobs = @{}

try {
    $listener.Start()
    Write-Host "Listening on port $ListenPort → ${RemoteHost}:$RemotePort"

    while ($true) {
        if ($listener.Pending()) {
            $client = $listener.AcceptTcpClient()
            
            $job = Start-ThreadJob -ScriptBlock {
                param($client, $RemoteHost, $RemotePort)
            
                $remote = [System.Net.Sockets.TcpClient]::new()
                $remote.Connect($RemoteHost, $RemotePort)
            
                $clientStream = $client.GetStream()
                $remoteStream = $remote.GetStream()
                $clientStream.ReadTimeout = 100
                $remoteStream.ReadTimeout = 100
                $buffer = New-Object byte[] 8192
            
                try {
                    while ($true) {
                        $DataReceived = $false
            
                        try {
                            $count = $clientStream.Read($buffer, 0, $buffer.Length)
                            if ($count -eq 0) { break }
                            $remoteStream.Write($buffer, 0, $count)
                            $remoteStream.Flush()
                            $DataReceived = $true
                            Write-Output "C→R: $count bytes"
                        }
                        catch {}
            
                        try {
                            $count = $remoteStream.Read($buffer, 0, $buffer.Length)
                            if ($count -eq 0) { break }
                            $clientStream.Write($buffer, 0, $count)
                            $clientStream.Flush()
                            $DataReceived = $true
                            Write-Output "R→C: $count bytes"
                        }
                        catch {}
            
                        if (-not $DataReceived) {
                            Start-Sleep -Milliseconds 50
                        }
                    }
                }
                finally {
                    $clientStream.Close()
                    $remoteStream.Close()
                    $client.Close()
                    $remote.Close()
                    Write-Output "Connection closed"
                }
            
            } -ArgumentList $client, $RemoteHost, $RemotePort

            $global:allJobs[$job.Id] = @{ Job = $job; Offset = 0 }
        }
        Start-Sleep -Milliseconds 100

        foreach ($entry in $allJobs.GetEnumerator()) {
            $job = $entry.Value.Job
            $offset = $entry.Value.Offset
            $output = Receive-Job -Job $job -Keep

            if ($output.Count -gt $offset) {
                $newOutput = $output[$offset..($output.Count - 1)]
                foreach ($line in $newOutput) {
                    Write-Host "[$($job.Id)] $line"
                }
                $allJobs[$job.Id].Offset = $output.Count
            }
        }        
    }        
}

finally {
    Write-Host "`nStopping listener..."
    $listener.Stop()
}

