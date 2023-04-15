BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'Continue'
  
  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"  
}

Describe 'Test: Start-SleepOrKey' {
  It "should return 'Null'" {
    $result = Start-SleepOrKey -Seconds 0
    $result | Should -Be $Null
  }
}
