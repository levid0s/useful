BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'Continue'
  
  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"
  
  Write-Host "PSScriptRoot: $PSScriptRoot"  
}

Describe 'Test: Get-ScriptPath' {
  It "should return '$PSScriptRoot'" {
    $result = Get-ScriptPath
    $result | Should -Be $PSScriptRoot
  }
}
