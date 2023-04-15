BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeAll {
  Import-Module Pester
  $PesterPreference = [PesterConfiguration]::Default
  $PesterPreference.Output.Verbosity = 'Detailed'
  $DebugPreference = 'Continue'

  . "$PSScriptRoot/../_PS-WinHelpers.ps1"
  $TestDrive = "$env:LOCALAPPDATA\Temp\$(New-Guid)"
  New-Item -Path $TestDrive -ItemType Directory -Force | Out-Null
  Write-Debug "TestDrive is: $TestDrive"
}

Describe 'Test Get-StreamContent.ps1' {
  Context 'Directory stream' {
    BeforeAll {
      $randomString = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
      $streamName = "pester.test.$randomString"
      $testDir = "$TestDrive\hello"
      $testStreamContent = 'Test Stream Content'
      Write-Debug "Stream path: ${testDir}:$streamName"
      New-Item -ItemType Directory -Path $testDir -Force | Out-Null
      Set-Content -Path "${testDir}:$streamName" -Value $testStreamContent
    }

    It 'returns content of an NTFS directory stream' {
      $content = Get-StreamContent -Path $testDir -StreamName $streamName
      $content | Should -Be $testStreamContent
    }

    It 'returns $null for a non-existent stream' {
      $content = Get-StreamContent -Path $testDir -StreamName 'nonExistentStream'
      $content | Should -Be $null
    }

    It 'handles relative paths' {
      Push-Location $TestDrive
      $content = Get-StreamContent -Path 'hello' -StreamName $streamName
      $content | Should -Be $testStreamContent
    }

    It 'handles forward slashes' {
      $testDir = "$TestDrive/hello"
      $content = Get-StreamContent -Path $testDir -StreamName $streamName
      $content | Should -Be $testStreamContent
    }

    It 'Byte output' {
      $content = Get-StreamContent -Path $testDir -StreamName $streamName -Encoding Byte
      $byteContent = [System.Text.Encoding]::UTF8.GetBytes("$testStreamContent`r`n")
      $content | Should -Be $byteContent
    }

    AfterAll {
      Pop-Location
      Remove-Item -Force -Recurse $testDir
    }
  }

  Context 'File stream' {
    BeforeAll {
      $randomString = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
      $streamName = "pester.test.$randomString"
      $testFile = "$TestDrive\hello.txt"
      $testStreamContent = 'Test Stream Content'
      Write-Debug "Stream path: ${testFile}:$streamName"
      New-Item -ItemType File -Path $testFile -Force | Out-Null
      Set-Content -Path $testFile -Value 'Test File Content'
      Set-Content -Path "${testFile}:$streamName" -Value $testStreamContent
    }

    It 'returns content of an NTFS file stream' {
      $content = Get-StreamContent -Path $testFile -StreamName $streamName
      $content | Should -Be $testStreamContent
    }

    It 'returns $null for a non-existent stream' {
      $content = Get-StreamContent -Path $testFile -StreamName 'nonExistentStream'
      $content | Should -Be $null
    }

    It 'handles relative paths' {
      Push-Location $TestDrive
      $content = Get-StreamContent -Path 'hello.txt' -StreamName $streamName
      $content | Should -Be $testStreamContent
    }

    It 'handles forward slashes' {
      $testFile = "$TestDrive/hello.txt"
      $content = Get-StreamContent -Path $testFile -StreamName $streamName
      $content | Should -Be $testStreamContent
    }

    It 'Byte output' {
      $content = Get-StreamContent -Path $testFile -StreamName $streamName -Encoding Byte
      $byteContent = [System.Text.Encoding]::UTF8.GetBytes("$testStreamContent`r`n")
      $content | Should -Be $byteContent
    }

    AfterAll {
      Pop-Location
      Remove-Item -Force $testFile
    }
  }
}

AfterAll {
  Remove-Item -Path $TestDrive -Recurse -Force
}
