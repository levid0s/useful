$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

Describe "Test: Get-RegValue HKEY_LOCAL_MACHINE\" {
  It "should return '1'" {
    $result = Get-RegValue -FullPath "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\Enable64Bit"
    $result | Should Be 1
  }
}

Describe "Test: Get-RegValue HKLM\" {
  It "should return '1'" {
    $result = Get-RegValue -FullPath "HKLM\SOFTWARE\Microsoft\.NETFramework\Enable64Bit"
    $result | Should Be 1
  }
}

Describe "Test: Get-RegValue HKLM:\" {
  It "should return '1'" {
    $result = Get-RegValue -FullPath "HKLM:\SOFTWARE\Microsoft\.NETFramework\Enable64Bit"
    $result | Should Be 1
  }
}

Describe "Test: Get-RegValue HKEY_CURRENT_USER\" {
  It "should return '0'" {
    $result = Get-RegValue -FullPath "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ServerAdminUI"
    $result | Should Be 0
  }
}

Describe "Test: Get-RegValue HKCU\" {
  It "should return '0'" {
    $result = Get-RegValue -FullPath "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ServerAdminUI"
    $result | Should Be 0
  }
}

Describe "Test: Get-RegValue HKCU:\" {
  It "should return '0'" {
    $result = Get-RegValue -FullPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ServerAdminUI"
    $result | Should Be 0
  }
}
