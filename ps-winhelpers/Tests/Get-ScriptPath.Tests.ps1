$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

Write-Host "PSScriptRoot: $PSScriptRoot"

Describe "Test: Get-ScriptPath" {
  It "should return '$PSScriptRoot'" {
    $result = Get-ScriptPath
    $result | Should Be $PSScriptRoot
  }
}
