# Dummy script for testing
param(
  $arg1,
  $arg2
)

Write-Host "Running dummy script..."

$HaltScriptOnParentExit = { Start-Job -ScriptBlock {
    param($ScriptPid)
    $parentProcessId = (Get-WmiObject Win32_Process -Filter "processid='$ScriptPid'").ParentProcessId
    $PSParent = Get-Process -Id $parentProcessId
    while (!$PSParent.HasExited) {
      Start-Sleep -Milliseconds 500
    }
    # Stop the PowerShell script
    Stop-Process $ScriptPid
  } -ArgumentList $pid | Out-Null
}
&$HaltScriptOnParentExit

do {
  # Waiting for parent job to be stopped..
  Start-Sleep -Milliseconds 500
} while ($true)

