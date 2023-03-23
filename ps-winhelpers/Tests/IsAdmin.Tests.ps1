$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

Describe "Test: IsAdmin" {
  It "should return 'False'" {
    $result = IsAdmin
    $result | Should Be $False
  }
}
