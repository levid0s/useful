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

Describe 'Get-DropboxIgnoredPath.ps1' {
  Context 'Directory' {
    BeforeAll {
      $randomString = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
      $testDir = "$TestDrive\$randomString"
      New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }

    It 'returns $true if a directory is ignored' {
      Set-DropboxIgnoredPath -Path $testDir
      $result = Get-DropboxIgnoredPath -Path $testDir
      $result | Should -Be $true
    }

    It 'returns $false if a directory is not ignored' {
      Set-DropboxIgnoredPath -Path $testDir -Unignore
      $result = Get-DropboxIgnoredPath -Path $testDir
      $result | Should -Be $false
    }

    It 'handles relative paths' {
      Push-Location $TestDrive
      Set-DropboxIgnoredPath -Path $randomString
      $result = Get-DropboxIgnoredPath -Path $randomString
      $result | Should -Be $true
    }

    It 'handles forward slashes in paths' {
      $testPath = "$TestDrive/$randomString"
      Set-DropboxIgnoredPath -Path $testPath
      $result = Get-DropboxIgnoredPath -Path $testPath
      $result | Should -Be $true
    }

    AfterAll {
      Pop-Location
    }
  }

  Context 'File' {
    BeforeAll {
      $randomString = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
      $testFile = "$TestDrive\$randomString.txt"
      New-Item -ItemType File -Path $testFile -Force | Out-Null
    }

    It 'returns $true if a file is ignored' {
      Set-DropboxIgnoredPath -Path $testFile
      $result = Get-DropboxIgnoredPath -Path $testFile
      $result | Should -Be $true
    }

    It 'returns $false if a file is not ignored' {
      Set-DropboxIgnoredPath -Path $testFile -Unignore
      $result = Get-DropboxIgnoredPath -Path $testFile
      $result | Should -Be $false
    }

    It 'handles relative paths' {
      Push-Location $TestDrive
      Set-DropboxIgnoredPath -Path "$randomString.txt"
      $result = Get-DropboxIgnoredPath -Path "$randomString.txt"
      $result | Should -Be $true
    }

    It 'handles forward slashes in paths' {
      $testPath = "$TestDrive/$randomString.txt"
      Set-DropboxIgnoredPath -Path $testPath
      $result = Get-DropboxIgnoredPath -Path $testPath
      $result | Should -Be $true
    }

    AfterAll {
      Pop-Location
    }
  }
}

AfterAll {
  Remove-Item -Path $TestDrive -Recurse -Force
}
