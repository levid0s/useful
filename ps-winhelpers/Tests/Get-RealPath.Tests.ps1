BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'Continue'

  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"
}

Describe 'Test: Get-RealPath' {
  
  Context 'Substed path' {

    BeforeAll {
      Write-Debug "TestDrive is: $TestDrive"
      $SubstDrive = 'o:'

      if (Test-Path $SubstDrive) {
        Throw 'Test drive already exists. TBC - find a free drive.'
      }
      subst $SubstDrive $TestDrive
      if (!(Test-Path $SubstDrive)) {
        Throw "Substing $SubstDrive to $TestDrive failed."
      }
      Set-Location $SubstDrive
    }

    It 'No parameters' {
      $result = Get-RealPath
      $result | Should -Be $TestDrive
    }

    It "`$null parameter" {
      $result = Get-RealPath $null
      $result | Should -Be $TestDrive
    } 

    It 'Dot path: .' {
      $result = Get-RealPath .
      $result | Should -Be $TestDrive
    }

    It 'Dot path subfolder: .\subfolder' {
      $TestFolder = Get-Random
      New-Item -Path "$PWD\$TestFolder" -Type Directory
      $result = Get-RealPath "./$TestFolder"
      $result | Should -Be "$TestDrive\$TestFolder"
      Remove-Item -Recurse -Force "$PWD\$TestFolder"
    }

    It 'Absolut Drive:' {
      $result = Get-RealPath "$SubstDrive"
      $result | Should -Be $TestDrive
    }

    It 'Absolut Drive:\' {
      $result = Get-RealPath "$SubstDrive\"
      $result | Should -Be $TestDrive
    }

    It 'Absolute path subfolder' {
      $TestFolder = Get-Random
      New-Item -Path "$SubstDrive\$TestFolder" -Type Directory
      $result = Get-RealPath "$SubstDrive\$TestFolder"
      $result | Should -Be "$TestDrive\$TestFolder"
    }

    It 'Absolute path: trailing slash removed' {
      $TestFolder = Get-Random
      New-Item -Path "$SubstDrive\$TestFolder" -Type Directory      
      $result = Get-RealPath "$SubstDrive\$TestFolder\"
      $result | Should -Be "$TestDrive\$TestFolder"
    }

    AfterAll {
      subst /d $SubstDrive
    }
  }

  Context 'Real path' {

    BeforeAll {
      $RealPath = "$env:SystemRoot"
      Set-Location $RealPath
    }

    It 'No parameters' {
      $result = Get-RealPath
      $result | Should -Be $RealPath
    }

    It "`$null parameter" {
      $result = Get-RealPath $null
      $result | Should -Be $RealPath
    } 

    It 'Dot path: .' {
      $result = Get-RealPath .
      $result | Should -Be $RealPath
    }

    It 'Dot path subfolder: .\System32' {
      $result = Get-RealPath '.\System32'
      $result | Should -Be "$RealPath\System32" 
    }

    It 'Absolute path: <RealPath>\System32' {
      $result = Get-RealPath "$RealPath\System32"
      $result | Should -Be "$RealPath\System32" 
    }

    It 'Trailing slash removed: <RealPath>\System32\' {
      $result = Get-RealPath "$RealPath\System32\"
      $result | Should -Be "$RealPath\System32"
    }
  }
}
