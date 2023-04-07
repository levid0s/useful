BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'Continue'
  
  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"  
}

Describe 'Test: Invoke-ToAdmin' {
  It "should return 'Null'" {
    $result = Invoke-ToAdmin
    $result | Should -Be $Null
  }
}
