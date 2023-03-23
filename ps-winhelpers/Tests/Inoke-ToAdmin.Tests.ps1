$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1


Describe "Test: Invoke-ToAdmin" {
  It "should return 'Null'" {
    $result = Invoke-ToAdmin
    $result | Should Be $Null
  }
}
