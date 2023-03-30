$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

$Timestamp = Get-Timestamp

$TaskPrefix = "PS-Testing-${Timestamp}"

# PowerShell get profile script
$TaskScript = "../Register-PowerShellScheduledTask.dummy.ps1"

Describe "Test: Register Group Scheduled Task" {
  $ShortGUID = (New-Guid).Guid.Split("-")[0]
  $Parameters = @{arg1 = $Timestamp; arg2 = "$ShortGUID-Initial" }
  $TimeLimit = Get-Random -Minimum 1 -Maximum 23
  $TimeInterval = Get-Random -Minimum 5 -Maximum 59

  $TaskName = "$TaskPrefix-Group"

  $GroupId = 'BUILTIN\Users'
  $cim = Register-PowerShellScheduledTask `
    -ScriptPath $TaskScript `
    -TaskName $TaskName `
    -Parameters $Parameters `
    -GroupId $GroupId `
    -AllowRunningOnBatteries $true `
    -ExecutionTimeLimit (New-TimeSpan -Hours $TimeLimit) `
    -TimeInterval $TimeInterval `
    -AtLogOn `
    -AtStartup

  It "Should create: '$TaskName'" {
    $cim.TaskName | Should be "$TaskName"
  }

  It "Should run as group: ``$groupId``" {
    $cim.Principal.GroupId | Should be (Split-Path $GroupId -Leaf)
  }

  It "Should be: allowed to run on batteries" {
    $cim.Settings.DisallowStartIfOnBatteries | Should be $false
  }

  It "Execution time limit should be: $TimeLimit hours           " {
    $cim.Settings.ExecutionTimeLimit | Should be "PT${TimeLimit}H"
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

  It "Should have AtStartup trigger" {
    $trigger = $cim.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskBootTrigger' }
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

  It "Should: uninstall successfully" {
    Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Uninstall

    $cim = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $cim | Should be $null
  }
}

Describe "Test: Register ``BUILTIN\Administrators`` Scheduled Task" {
  $ShortGUID = (New-Guid).Guid.Split("-")[0]
  $Parameters = @{arg1 = $Timestamp; arg2 = "$ShortGUID-Initial" }
  $TimeLimit = Get-Random -Minimum 1 -Maximum 23
  $TaskName = "$TaskPrefix-Group"

  $GroupId = 'BUILTIN\Administrators'
  $cim = Register-PowerShellScheduledTask `
    -ScriptPath $TaskScript `
    -TaskName $TaskName `
    -Parameters $Parameters `
    -GroupId $GroupId `
    -AllowRunningOnBatteries $true `
    -ExecutionTimeLimit (New-TimeSpan -Hours $TimeLimit) `
    -TimeInterval 15 `
    -AtLogOn `
    -AtStartup

  It "Should create: '$TaskName'" {
    $cim.TaskName | Should be "$TaskName"
  }

  It "Should run as group: ``$groupId``" {
    $cim.Principal.GroupId | Should be (Split-Path $GroupId -Leaf)
  }

  It "Should be: allowed to run on batteries" {
    $cim.Settings.DisallowStartIfOnBatteries | Should be $false
  }

  It "Execution time limit should be: $TimeLimit hours           " {
    $cim.Settings.ExecutionTimeLimit | Should be "PT${TimeLimit}H"
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

  It "Should have AtStartup trigger" {
    $trigger = $cim.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskBootTrigger' }
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

  It "Should: uninstall successfully" {
    Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Uninstall

    $cim = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $cim | Should be $null
  }
}


Describe "Test: Register Admin Scheduled Task" {
  $ShortGUID = (New-Guid).Guid.Split("-")[0]
  $Parameters = @{arg1 = $Timestamp; arg2 = "$ShortGUID-Initial" }
  $TimeLimit = Get-Random -Minimum 1 -Maximum 23
  $TaskName = "$TaskPrefix-Admin"

  $cim = Register-PowerShellScheduledTask `
    -ScriptPath $TaskScript `
    -TaskName $TaskName `
    -Parameters $Parameters `
    -ExecutionTimeLimit (New-TimeSpan -Hours $TimeLimit) `
    -AsAdmin `
    -TimeInterval 15 `
    -AtLogOn `
    -AtStartup

  It "Should create: '$TaskName'" {
    $cim.TaskName | Should be "$TaskName"
  }

  It "Should have: RunLevel Highest" {
    $cim.Principal.RunLevel | Should be "Highest"
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

  It "Should have AtStartup trigger" {
    $trigger = $cim.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskBootTrigger' }
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

  It "Should: uninstall successfully" {
    Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Uninstall

    $cim = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $cim | Should be $null
  }
}