BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  # $VerbosePreference = 'Continue'
  
  . N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1  
}

Describe 'Test: Start-SleepUntilTrue' {
  Context 'Wait for condition to become true' {
    BeforeAll {
      $delaySec = 1
      $testProcess = 'notepad.exe'

      $time = Measure-Command { 
        $process = Start-Process 'cmd' -ArgumentList '/c', 'sleep', $delaySec, '&', 'start', '/min', $testProcess -WindowStyle Hidden -PassThru
  
        # Wait until a child process of 'notepad' is started
        $result = Start-SleepUntilTrue -Condition { Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessID -eq $process.Id -and $_.Name -eq $testProcess } } -Seconds ($delaySec * 10)
      }  
    }

    It 'Should start successfully <testProcess>' {
      $result | Should -BeOfType 'CimInstance'
    }

    It 'Should wait <delaySec>s for <testProcess> to start' {
      $time.TotalSeconds | Should -BeGreaterOrEqual $delaySec
      $time.TotalSeconds | Should -BeLessOrEqual ($delaySec + 1)
    }

    AfterAll {
      $children = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessID -eq $process.Id }
      $children | Stop-Process -Force -ErrorAction SilentlyContinue
      Stop-Process -Id $result.ProcessId -ErrorAction SilentlyContinue
    }
  }

  Context 'Wait for timeout' {
    BeforeAll {
      $delaySec = 3

      $time = Measure-Command { 
  
        # Wait until a child process of 'notepad' is started
        $result = Start-SleepUntilTrue -Condition { Get-CimInstance Win32_Process | Where-Object { $_.ProcessName -eq 'asdfxxefllo' } } -Seconds $delaySec
      }
    }

    It 'Should wait <delaySec>s for timeout' {
      $time.TotalSeconds | Should -BeGreaterOrEqual $delaySec
      $time.TotalSeconds | Should -BeLessOrEqual ($delaySec + 1)
    }

    It 'Result should be null on timeout' {
      $result | Should -Be $Null
    }
  }

  ## TODO - Test Checking frequency
}
