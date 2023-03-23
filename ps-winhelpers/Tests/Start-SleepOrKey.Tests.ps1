$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

Describe "Test: Start-SleepOrKey" {
  It "should return 'Null'" {
    $result = Start-SleepOrKey -Seconds 0
    $result | Should Be $Null
  }
}
