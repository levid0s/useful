BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'SilentlyContinue'

  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"
}

Describe 'Get-RealGitRoot Tests' {
  Context 'Real paths' {
    Describe 'Non-Git paths' {
      BeforeAll {
        $Location = "$env:LOCALAPPDATA\Temp\Pester\$(New-Guid)"
        New-Item -Path $Location -ItemType Directory -Force | Out-Null
        New-Item -Path "$Location\folder1" -ItemType Directory -Force | Out-Null
        New-Item -Path "$Location\folder1\file1.txt" -ItemType File -Force | Out-Null
      }

      It 'Directory' {
        $result = Get-RealGitroot "$Location\folder1"
        $result | Should -Be "$Location\folder1"
      }

      It 'File' {
        $result = Get-RealGitroot "$Location\folder1\file1.txt"
        $result | Should -Be "$Location\folder1"
      }
    
      AfterAll {
        Remove-Item -Path $Location -Recurse -Force
      }
    }

    Describe 'Git paths' {
      BeforeAll {
        $Location = "$env:LOCALAPPDATA\Temp\Pester\$(New-Guid)"
        git init $Location 2>$null
        if ($LASTEXITCODE -ne 0) {
          Throw 'git init failed.'
        }
        New-Item -Path "$Location\folder1" -ItemType Directory -Force | Out-Null
        New-Item -Path "$Location\folder1\folder2" -ItemType Directory -Force | Out-Null
        New-Item -Path "$Location\folder1\folder2\file1.txt" -ItemType File -Force | Out-Null
      }

      It 'Directory' {
        $result = Get-RealGitroot "$Location\folder1"
        $result | Should -Be $Location
      }

      It 'Subdirectory' {
        $result = Get-RealGitroot "$Location\folder1\folder2"
        $result | Should -Be $Location
      }

      It 'File' {
        $result = Get-RealGitroot "$Location\folder1\folder2\file1.txt"
        $result | Should -Be $Location
      }
    
      AfterAll {
        Remove-Item -Path $Location -Recurse -Force
      }
    }
  }

  Context 'SUBSTED paths' {
    BeforeAll {
      $SubstDrive = 'o:'
      if (Test-Path $SubstDrive) {
        Throw 'Test drive already exists. TBC - find a free drive.'
      }

      $Location = "$env:LOCALAPPDATA\Temp\Pester\$(New-Guid)"
      New-Item -Path $Location -ItemType Directory -Force | Out-Null
      subst $SubstDrive $Location
    }

    Describe 'Non-Git paths' {
      BeforeAll {
        $Location = "$Location\non-git"
        New-Item -Path "$Location\folder1" -ItemType Directory -Force | Out-Null
        New-Item -Path "$Location\folder1\file1.txt" -ItemType File -Force | Out-Null
      }

      It 'Directory' {
        $result = Get-RealGitroot "$SubstDrive\non-git\folder1"
        $result | Should -Be "$Location\folder1"
      }

      It 'File' {
        $result = Get-RealGitroot "$SubstDrive\non-git\folder1\file1.txt"
        $result | Should -Be "$Location\folder1"
      }
    }

    Describe 'Git paths' {
      BeforeAll {
        $Location = "$Location\yes-git"
        git init $Location 2>$null
        if ($LASTEXITCODE -ne 0) {
          Throw 'git init failed.'
        }
        New-Item -Path "$Location\folder1" -ItemType Directory -Force | Out-Null
        New-Item -Path "$Location\folder1\folder2" -ItemType Directory -Force | Out-Null
        New-Item -Path "$Location\folder1\folder2\file1.txt" -ItemType File -Force | Out-Null
      }

      It 'Directory' {
        $result = Get-RealGitroot "$SubstDrive\yes-git\folder1"
        $result | Should -Be $Location
      }

      It 'Subdirectory' {
        $result = Get-RealGitroot "$SubstDrive\yes-git\folder1\folder2"
        $result | Should -Be $Location
      }

      It 'File' {
        $result = Get-RealGitroot "$SubstDrive\yes-git\folder1\folder2\file1.txt"
        $result | Should -Be $Location
      }
    }

    AfterAll {
      subst $SubstDrive /D
      Remove-Item -Path $Location -Recurse -Force
    }
  }

}
