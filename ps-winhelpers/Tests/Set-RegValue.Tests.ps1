$DebugPreference = "Continue"
$InformationPreference = "Continue"
$VerbosePreference = "Continue"
$TidyUp = $False

. N:\src\useful\ps-winhelpers\_PS-WinHelpers.ps1

Describe "Test: Set-RegValue (DWord)" {
  Set-RegValue -FullPath "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-DWord" -Value 1 -Type "DWord"
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-DWord'
  It "should return '1'" {
    $result | Should Be 1
  }
  It "should be of type 'Int32'" {
    $result.GetType().Name | Should Be "Int32"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-DWord'
  }
}

Describe "Test: Set-RegValue (REG_DWORD)" {
  Set-RegValue -FullPath "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-REG_DWORD" -Value 1 -Type "REG_DWORD"
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_DWORD'
  It "should return '1'" {
    $result | Should Be 1
  }
  It "should be of type 'Int32'" {
    $result.GetType().Name | Should Be "Int32"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_DWORD'
  }
}


Describe "Test: Set-RegValue (QWord)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-QWord' -Value 1 -Type 'QWord'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-QWord'
  It "should return '1'" {
    $result | Should Be 1
  }
  It "should be of type 'Int64'" {
    $result.GetType().Name | Should Be "Int64"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-QWord'
  }
}

Describe "Test: Set-RegValue (REG_QWORD)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-REG_QWORD' -Value 1 -Type 'REG_QWORD'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_QWORD'
  It "should return '1'" {
    $result | Should Be 1
  }
  It "should be of type 'Int64'" {
    $result.GetType().Name | Should Be "Int64"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_QWORD'
  }
}

Describe "Test: Set-RegValue (String)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-String' -Value 'Hello!' -Type 'String'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-String'
  It "should return 'Hello!'" {
    $result | Should Be 'Hello!'
  }
  It "should be of type 'String'" {
    $result.GetType().Name | Should Be "String"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-String'
  }
}

Describe "Test: Set-RegValue (REG_SZ)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-REG_SZ' -Value 'Hello!' -Type 'REG_SZ'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_SZ'
  It "should return 'Hello!'" {
    $result | Should Be 'Hello!'
  }
  It "should be of type 'String'" {
    $result.GetType().Name | Should Be "String"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_SZ'
  }
}

Describe "Test: Set-RegValue (ExpandString)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-ExpandString' -Value '%APPDATA%\Hello!' -Type 'ExpandString'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-ExpandString'
  It "should return '%APPDATA%\Hello!'" {
    $result | Should Be "$env:APPDATA\Hello!"
  }
  It "should be of type 'String'" {
    $result.GetType().Name | Should Be "String"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-ExpandString'
  }
}

Describe "Test: Set-RegValue (REG_EXPAND_SZ)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-REG_EXPAND_SZ' -Value '%APPDATA%\Hello!' -Type 'REG_EXPAND_SZ'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_EXPAND_SZ'
  It "should return '%APPDATA%\Hello!'" {
    $result | Should Be "$env:APPDATA\Hello!"
  }
  It "should be of type 'String'" {
    $result.GetType().Name | Should Be "String"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_EXPAND_SZ'
  }
}

Describe "Test: Set-RegValue (MultiString)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-MultiString' -Value "Hello", "World", "You!" -Type 'MultiString'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-MultiString'
  It "should be 'Hello', 'World', 'You!'" {
    $result | Should Be 'Hello', 'World', 'You!'
  }
  It "should be of type 'String[]'" {
    $result.GetType().Name | Should Be "String[]"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-MultiString'
  }
}

Describe "Test: Set-RegValue (REG_MULTI_SZ)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-REG_MULTI_SZ' -Value "Hello", "World", "You!" -Type 'REG_MULTI_SZ'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_MULTI_SZ'
  It "should be 'Hello', 'World', 'You!'" {
    $result | Should Be 'Hello', 'World', 'You!'
  }
  It "should be of type 'String[]'" {
    $result.GetType().Name | Should Be "String[]"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-REG_MULTI_SZ'
  }
}

Describe "Test: Set-RegValue (HKCU\)" {
  Set-RegValue -FullPath 'HKCU\SOFTWARE\Microsoft\Accessibility\TempPesterTest-HKCU' -Value 'Hello!' -Type 'String'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-HKCU'
  It "should return 'Hello!'" {
    $result | Should Be 'Hello!'
  }
  It "should be of type 'String'" {
    $result.GetType().Name | Should Be "String"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-HKCU'
  }
}

Describe "Test: Set-RegValue (HKCU:\)" {
  Set-RegValue -FullPath 'HKCU:\SOFTWARE\Microsoft\Accessibility\TempPesterTest-HKCU2' -Value 'Hello!' -Type 'String'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-HKCU2'
  It "should return 'Hello!'" {
    $result | Should Be 'Hello!'
  }
  It "should be of type 'String'" {
    $result.GetType().Name | Should Be "String"
  }
  if ($TidyUp) {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-HKCU'
  }
}


<# - Not implemented
Describe "Test: Set-RegValue (Binary)" {
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Accessibility\TempPesterTest-Binary' -Value 12 -Type 'Binary'
  $result = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Accessibility" -name 'TempPesterTest-MultiString'
  It "should be 1100" {
    $result | Should Be 12
  }
  It "should be of type 'Byte[]'" {
    $result.GetType().Name | Should Be "Byte[]"
  }
}
#>
