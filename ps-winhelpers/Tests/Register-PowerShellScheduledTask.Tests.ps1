## TODO - TO FIX
BeforeAll {
  # $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  # $VerbosePreference = 'Continue'
  
  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"  
  $Timestamp = Get-Timestamp
  $TaskPrefix = "PS-Testing-${Timestamp}"
  $TaskScript = "$PSScriptRoot/Register-PowerShellScheduledTask.zdummy.ps1"
}

Describe 'Test: Register Basic Scheduled Task' {
  BeforeAll {
    $ShortGUID = (New-Guid).Guid.Split('-')[0]
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
  }

  It "Should create: '<TaskName>'" {
    $cim.TaskName | Select-Object -First 1 | Should -Be "$TaskName"
  }

  It 'Execution time limit: <TimeLimit> hours           ' {
    $cim.Settings.ExecutionTimeLimit | Should -Be "PT${TimeLimit}H"
  }

  It 'Allowed to run on batteries ✓' {
    $cim.Settings.DisallowStartIfOnBatteries | Should -Be $false
  }

  It 'Run as: <env:USERNAME>' {
    $cim.Principal.UserId | Should -Be $env:USERNAME
  }

  It 'Time interval: <TimeInterval> minutes' {
    $trigger = $cim.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskDailyTrigger' }
    $trigger | Should -Not -BeNullOrEmpty
    $trigger.CimInstanceProperties['Repetition'].Value.Interval | Should -Be "PT${TimeInterval}M"
    $trigger.CimInstanceProperties['Repetition'].Value.StopAtDurationEnd | Should -Be $false
  }

  It 'AtLogon trigger present' {
    $trigger = $cim.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }
    $trigger | Should -Not -BeNullOrEmpty
  }

  It 'Task starts successfully' {
    Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $cimInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Debug "Diff: $(($cimInfo.LastRunTime - (Get-Date)).Seconds) seconds"
    [Math]::Abs(($cimInfo.LastRunTime - (Get-Date)).Seconds) | Should -BeLessThan 60
  }

  It 'Task is running' {
    $cim = Get-ScheduledTask -TaskName $TaskName
    $state = Start-SleepUntilTrue { $cim.State -eq 'Running' } -Seconds 15
    $state | Should -Be $true
  }

  It 'Process is RUNNING' {
    $process = Start-SleepUntilTrue { Get-WmiObject Win32_Process | Where-Object Commandline -Like "*$(Split-Path $TaskScript -Leaf)*" }
    $process | Should -Not -BeNullOrEmpty
  }

  It 'Process arguments present' {
    $process = Get-WmiObject Win32_Process | Where-Object Commandline -Like "*$ShortGUID-Initial*"
    $process | Should -Not -BeNullOrEmpty
  }

  It 'PowerShell script stops when the Job is ended' {
    $process = Get-WmiObject Win32_Process | Where-Object Commandline -Like "*$ShortGUID-Initial*"
    $PSProcess = Get-Process -Id $process.processid
    Stop-ScheduledTask -TaskName $TaskName
    Start-SleepUntilTrue { $PSProcess.HasExited } -Seconds 15
    $PSProcess.HasExited | Should -Be $true
  }

  Context 'Test Updating Existing Task' {
    BeforeAll {
      $NewTimeLimit = Get-Random -Minimum 1 -Maximum 23
      $NewTimeInterval = Get-Random -Minimum 5 -Maximum 59
      Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
      Write-Debug 'Waiting for Task to start up..'
      $process = Start-SleepUntilTrue { Get-WmiObject Win32_Process | Where-Object Commandline -Like "*$ShortGUID-Initial*" }
      $OldPSProcess = Get-Process -Id $process.processid
      $NewParameters = @{arg1 = $Timestamp; arg2 = "$ShortGUID-Updated" }
      $cim = Register-PowerShellScheduledTask `
        -ScriptPath $TaskScript `
        -TaskName $TaskName `
        -Parameters $NewParameters `
        -ExecutionTimeLimit (New-TimeSpan -Hours $NewTimeLimit) `
        -TimeInterval $NewTimeInterval
    }

    It 'Should: update existing Scheduled Task correctly' {
      $cim.TaskName | Select-Object -First 1 | Should -Be "$TaskName"
      Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
      Write-Debug 'Waiting for new task to start..'
      $process = Start-SleepUntilTrue -Condition { Get-WmiObject Win32_Process | Where-Object Commandline -Like "*$ShortGUID-Updated*" }
      Write-Debug 'Waiting for old task to stop..'
      Start-SleepUntilTrue -Condition { $OldPSProcess.HasExited } -Seconds 15 | Out-Null
      $OldPSProcess.HasExited | Should -Be $true
      $process | Should -Not -BeNullOrEmpty
    }
    It 'Updated task: Execution time limit: <NewTimeLimit> hours       ' {
      $cim = Get-ScheduledTask -TaskName $TaskName
      $cim.Settings.ExecutionTimeLimit | Should -Be "PT${NewTimeLimit}H"
    }
  }

  It 'Updated task: NOT allowed to run on batteries' {
    $cim = Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Parameters $Parameters `
      -AllowRunningOnBatteries $false `
      -AtLogOn
    $cim = $cim | Select-Object -Last 1
    $cim.Settings.DisallowStartIfOnBatteries | Should -Be $true
  }

  It 'Updated task: Only start at Logon' {
    $cimNew = Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Parameters $Parameters `
      -AllowRunningOnBatteries $false `
      -AtLogOn

    $cimNew = $cimNew | Select-Object -Last 1

    $cimNew.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' } | Should -Not -BeNullOrEmpty
    $cimNew.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskDailyTrigger' } | Should -BeNullOrEmpty
    $cimNew.Triggers.Count | Should -Be 1
  }

  It 'Uninstalls successfully' {
    Register-PowerShellScheduledTask `
      -ScriptPath $TaskScript `
      -TaskName $TaskName `
      -Uninstall

    $cim = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    $cim | Should -Be $null
  }

  It 'Process STOPPED after task uninstall' {
    $process = Get-WmiObject Win32_Process | Where-Object Commandline -Like "*$(Split-Path $TaskScript -Leaf)*"
    $process | Should -BeNullOrEmpty
  }
}
