BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'Continue'
  
  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"  
}

Describe 'Test: Install-ModuleIfNotPresent' {
  It "should return 'Null'" {
    $result = Install-ModuleIfNotPresent 'Pester'
    $result | Should -Be $Null
  }
}
