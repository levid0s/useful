BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeDiscovery {
  Import-Module Pester
  $PesterPreference = [PesterConfiguration]::Default
  $PesterPreference.Output.Verbosity = 'Detailed'
}

BeforeAll {
  $DebugPreference = 'Continue'

  . "$PSScriptRoot/../_PS-WinHelpers.ps1"
  $TestDrive = "$env:LOCALAPPDATA\Temp\$(New-Guid)"
  New-Item -Path $TestDrive -ItemType Directory -Force | Out-Null
  Write-Debug "TestDrive is: $TestDrive"
}

Describe 'Test Set-DropboxIgnoredPath.ps1' {
  Context 'Directory' {
    BeforeAll {
      $randomString = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
      $testDir = "$TestDrive\$randomString"
      New-Item -ItemType Directory -Path $testDir -Force | Out-Null  
    }

    It 'ignores a dirctory' {
      Set-DropboxIgnoredPath -Path $testDir
      $value = Get-StreamContent -Path $testDir -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'ignores a dirctory that''s already ignored' {
      Set-DropboxIgnoredPath -Path $testDir
      $value = Get-StreamContent -Path $testDir -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'unignores a directory' {
      Set-DropboxIgnoredPath -Path $testDir -Unignore
      $value = Get-StreamContent -Path $testDir -StreamName 'com.dropbox.ignored'
      $value | Should -BeNullOrEmpty
    }

    It 'unignores a directory that''s already unignored' {
      Set-DropboxIgnoredPath -Path $testDir -Unignore
      $value = Get-StreamContent -Path $testDir -StreamName 'com.dropbox.ignored'
      $value | Should -BeNullOrEmpty
    }

    It 'handles relative paths' {
      Push-Location $TestDrive
      Set-DropboxIgnoredPath -Path $randomString
      $value = Get-StreamContent -Path $randomString -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'handles forward slashes in paths' {
      $testPath = "$TestDrive/$randomString"
      Set-DropboxIgnoredPath -Path $testPath
      $value = Get-StreamContent -Path $testPath -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'non-existent path should throw an error' {
      $testPath = "$TestDrive/$(New-Guid)"
      { Set-DropboxIgnoredPath -Path $testPath } | Should -Throw "Error: Path $testPath not found."
    }
    
    AfterAll {
      Pop-Location
    }
  }

  Context 'Files' {
    BeforeAll {
      $randomString = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ }) + '.txt'
      $testFile = "$TestDrive\$randomString"
      New-Item -ItemType File -Path $testFile -Force | Out-Null
    }

    It 'ignores a file' {
      Set-DropboxIgnoredPath -Path $testFile
      $value = Get-StreamContent -Path $testFile -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'ignores a file that''s already ignored' {
      Set-DropboxIgnoredPath -Path $testFile
      $value = Get-StreamContent -Path $testFile -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'unignores a file' {
      Set-DropboxIgnoredPath -Path $testFile -Unignore
      $value = Get-StreamContent -Path $testFile -StreamName 'com.dropbox.ignored'
      $value | Should -BeNullOrEmpty
    }

    It 'unignores a file that''s already unignored' {
      Set-DropboxIgnoredPath -Path $testFile -Unignore
      $value = Get-StreamContent -Path $testFile -StreamName 'com.dropbox.ignored'
      $value | Should -BeNullOrEmpty
    }

    It 'handles relative paths' {
      Push-Location $TestDrive
      Set-DropboxIgnoredPath -Path $randomString
      $value = Get-StreamContent -Path $randomString -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'handles forward slashes in paths' {
      $testPath = "$TestDrive/$randomString"
      Set-DropboxIgnoredPath -Path $testPath
      $value = Get-StreamContent -Path $testPath -StreamName 'com.dropbox.ignored'
      $value | Should -Be 1
    }

    It 'non-existent path should throw an error' {
      $testPath = "$TestDrive/$(New-Guid).txt"
      { Set-DropboxIgnoredPath -Path $testPath } | Should -Throw "Error: Path $testPath not found."
    }

    AfterAll {
      Pop-Location
    }
  }
}

AfterAll {
  Remove-Item -Path $TestDrive -Recurse -Force
}
