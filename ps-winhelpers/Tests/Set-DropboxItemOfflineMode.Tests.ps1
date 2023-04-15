BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeDiscovery {
  . "$PSScriptRoot/../_PS-WinHelpers.ps1"
  if (!(Get-DropboxInstallPath)) {
    throw 'Dropbox is not installed on this machine'
  }
}

BeforeAll {
  . "$PSScriptRoot/../_PS-WinHelpers.ps1"
  $VerbosePreference = 'Continue'
  $DebugPreference = 'Continue'
}

Describe 'Test Set-DropboxItemOfflineMode.ps1' {
  BeforeAll {
    $DbxRoot = Get-DropboxInstallPath
    $TestDrive = "${DbxRoot}\pester-$(Get-Random)"
    New-Item -ItemType Directory -Path $TestDrive -Force | Out-Null
    Write-Debug "TestDrive is: $TestDrive"
    if ($VerbosePreference -eq 'Continue') {
      explorer "$TestDrive"
    }
    [int]$DelayMs = 2000
  }

  Context 'Folder' {
    BeforeAll {
      $TestFolder = "${TestDrive}\testfolder"
      New-Item -ItemType Directory -Path $TestFolder -Force | Out-Null  
    }

    BeforeEach {
      Start-Sleep -Milliseconds $DelayMs
    }

    It 'Should set the offline mode on the item' {
      { Set-DropboxItemOfflineMode -Path $TestFolder -Mode 'Offline' } | Should -Not -Throw
    }

    It 'Should set the offline mode on the item that''s already offline' {
      { Set-DropboxItemOfflineMode -Path $TestFolder -Mode 'Offline' } | Should -Not -Throw
    }

    It 'Should set online-only mode on the item' {
      { Set-DropboxItemOfflineMode -Path $TestFolder -Mode 'OnlineOnly' } | Should -Not -Throw
    }

    It 'Should set online-only mode on the item that''s already online-only' {
      { Set-DropboxItemOfflineMode -Path $TestFolder -Mode 'OnlineOnly' } | Should -Not -Throw
    }

  }

  Context 'File' {
    BeforeAll {
      $TestFile = "${TestDrive}\testfile.txt"
      Get-Process > $TestFile
    }

    BeforeEach {
      Start-Sleep -Milliseconds ($DelayMs * 2)
    }

    It 'Should set the offline mode on the item' {
      { Set-DropboxItemOfflineMode -Path $TestFile -Mode 'Offline' } | Should -Not -Throw
    }

    It 'Should set the offline mode on the item that''s already offline' {
      { Set-DropboxItemOfflineMode -Path $TestFile -Mode 'Offline' } | Should -Not -Throw
    }

    It 'Should set online-only mode on the item' {
      { Set-DropboxItemOfflineMode -Path $TestFile -Mode 'OnlineOnly' } | Should -Not -Throw
    }

    It 'Should set online-only mode on the item that''s already online-only' {
      { Set-DropboxItemOfflineMode -Path $TestFile -Mode 'OnlineOnly' } | Should -Not -Throw
    }
  }

  AfterAll {
    Remove-Item -Path $TestDrive -Recurse -Force | Out-Null
  }
}
