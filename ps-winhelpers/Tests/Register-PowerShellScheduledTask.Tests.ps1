$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

$Timestamp = Get-Timestamp
$TaskPrefix = "PS-Testing-${Timestamp}"
$TaskScript = "./Register-PowerShellScheduledTask.dummy.ps1"

Describe "Test: Register Basic Scheduled Task" {
  $ShortGUID = (New-Guid).Guid.Split("-")[0]
  $Parameters = @{arg1 = $Timestamp; arg2 = "$ShortGUID-Initial" }
  $TimeLimit = Get-Random -Minimum 1 -Maximum 23
  $TimeInterval = Get-Random -Minimum 5 -Maximum 59
  $TaskName = "$TaskPrefix-Basic"

  $cim = Register-PowerShellScheduledTask `
    -ScriptPath $TaskScript `
    -TaskName $TaskName `
    -Parameters $Parameters `
    -AllowRunningOnBatteries $true `
    -ExecutionTimeLimit (New-TimeSpan -Hours $TimeLimit) `
    -TimeInterval $TimeInterval `
    -AtLogon

  It "Should create: '$TaskName'" {
    $cim.TaskName | Should be "$TaskName"
  }

  It "Execution time limit should be: $TimeLimit hours           " {
    $cim.Settings.ExecutionTimeLimit | Should be "PT${TimeLimit}H"
  }

  It "Should be: allowed to run on batteries" {
    $cim.Settings.DisallowStartIfOnBatteries | Should be $false
  }

  It "Should run as: ``$env:USERNAME``" {
    $cim.Principal.UserId | Should be $env:USERNAME
  }

  It "Time interval should be: $TimeInterval minutes" {
    $trigger = $cim.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskDailyTrigger' }
    $trigger | Should Not BeNullOrEmpty
    $trigger.CimInstanceProperties["Repetition"].Value.Interval | Should Be "PT${TimeInterval}M"
    $trigger.CimInstanceProperties["Repetition"].Value.StopAtDurationEnd | Should Be $false
  }

  It "Should have AtLogon trigger" {
    $trigger = $cim.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }
    $trigger | Should Not BeNullOrEmpty
  }

  It "Should: start successfully" {
    Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $cimInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Debug "LastRunTime: $($CimInfo.LastRunTime)"
    Write-Debug "Current Date: $(Get-Date)"
    Write-Debug "Diff: $(($cimInfo.LastRunTime - (Get-Date)).Seconds) seconds"
    [Math]::Abs(($cimInfo.LastRunTime - (Get-Date)).Seconds) | Should BeLessThan 60
  }

  It "Process should be: RUNNING" {
    $process = Get-WmiObject Win32_Process | Where-Object Commandline -like "*$(Split-Path $TaskScript -Leaf)*"
    $process | Should Not BeNullOrEmpty
  }

  It "Process arguments: should be correct" {
    $process = Get-WmiObject Win32_Process | Where-Object Commandline -like "*$ShortGUID-Initial*"
    $process | Should Not BeNullOrEmpty
  }

  It "PowerShell script: should stop when the Job is ended" {
    $process = Get-WmiObject Win32_Process | Where-Object Commandline -like "*$ShortGUID-Initial*"
    $PSProcess = Get-Process -Id $process.processid
    Stop-ScheduledTask -TaskName $TaskName
    Start-Sleep 2
    $PSProcess.HasExited | Should be $true
  }

  ###  TEST: Updating settings
  $TimeLimit = Get-Random -Minimum 1 -Maximum 23
  $TimeInterval = Get-Random -Minimum 5 -Maximum 59

  It "Should: update existing Scheduled Task correctly" {
    Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Debug "Waiting for Task to start up.."
    $process = Start-SleepOrCondition { Get-WmiObject Win32_Process | Where-Object Commandline -like "*$ShortGUID-Initial*" }
    $OldPSProcess = Get-Process -Id $process.processid
    $Parameters = @{arg1 = $Timestamp; arg2 = "$ShortGUID-Updated" }
    $cim = Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Parameters $Parameters `
      -ExecutionTimeLimit (New-TimeSpan -Hours $TimeLimit) `
      -TimeInterval $TimeInterval

    $cim.TaskName | Should be "$TaskName"
    Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Debug "Waiting for new task to start.."
    $process = Start-SleepOrCondition -Condition { Get-WmiObject Win32_Process | Where-Object Commandline -like "*$ShortGUID-Updated*" }
    Write-Debug "Waiting for old task to stop.."
    Start-SleepOrCondition -Condition { $OldPSProcess.HasExited } -Seconds 15 | Out-Null
    $OldPSProcess.HasExited | Should be $true
    $process | Should Not BeNullOrEmpty
  }

  it "Updated task execution time limit should be: $TimeLimit hours       " {
    $cim = Get-ScheduledTask -TaskName $TaskName
    $cim.Settings.ExecutionTimeLimit | Should be "PT${TimeLimit}H"
  }

  Remove-Variable cim
  $cim = Register-PowerShellScheduledTask `
    -ScriptPath $TaskScript `
    -TaskName $TaskName `
    -Parameters $Parameters `
    -AllowRunningOnBatteries $false `
    -AtLogOn

  It "Updated task should be: NOT allowed to run on batteries" {
    $cim.Settings.DisallowStartIfOnBatteries | Should be $true
  }

  It "Updated task should only start at Logon" {
    $cimNew = Get-ScheduledTask -TaskName $TaskName
    $cimNew.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' } | Should Not BeNullOrEmpty
    $cimNew.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskDailyTrigger' } | Should BeNullOrEmpty
    $cimNew.Triggers.Count | Should Be 1
  }
  return
  It "Should: uninstall successfully" {
    Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Uninstall

    $cim = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $cim | Should be $null
  }
}
