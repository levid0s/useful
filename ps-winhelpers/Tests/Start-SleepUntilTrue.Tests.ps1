$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

Describe "Test: Start-SleepUntilTrue" {
  It "should wait until Notepad is started" {
    $result = Start-SleepUntilTrue -Condition { Get-Process -Name "notepad" -ErrorAction SilentlyContinue } -Seconds 60
    $result | Should BeOfType "System.Diagnostics.Process"
  }

  It "should wait until one of the PowerShell processes have exited" {
    $p = Get-Process "powershell"
    Write-Host "$($p.HasExited)"
    $result = Start-SleepUntilTrue -Condition { $p.HasExited } -Seconds 60
    Write-Host "$($p.HasExited)"
    $result | Should Not BeNullOrEmpty
  }

  It "should return 'Null'" {
    $StartTime = Get-Date
    $result = Start-SleepUntilTrue -Condition { [TimeSpan]::Parse((Get-Date) - $StartTime).TotalSeconds -gt 10 } -Seconds 60
    $result | Should Be $Null
  }
}
