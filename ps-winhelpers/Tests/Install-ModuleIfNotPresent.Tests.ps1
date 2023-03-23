$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

Describe "Test: Install-ModuleIfNotPresent" {
  It "should return 'Null'" {
    $result = Install-ModuleIfNotPresent "Pester"
    $result | Should Be $Null
  }
}
