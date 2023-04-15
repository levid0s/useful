BeforeDiscovery {
  . "$PSScriptRoot/_BeforeDiscoveryAll.ps1"
}

BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'Continue'
  
  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"  
}


Describe 'Testing Get-RegValue function' {
  It 'prefix: HKEY_LOCAL_MACHINE\' {
    $result = Get-RegValue -FullPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\Enable64Bit'
    $result | Should -Be 1
  }

  It 'prefix: HKLM\' {
    $result = Get-RegValue -FullPath 'HKLM\SOFTWARE\Microsoft\.NETFramework\Enable64Bit'
    $result | Should -Be 1
  }

  It 'Prefix: HKLM:\' {
    $result = Get-RegValue -FullPath 'HKLM:\SOFTWARE\Microsoft\.NETFramework\Enable64Bit'
    $result | Should -Be 1
  }

  It 'prefix: HKEY_CURRENT_USER\' {
    $result = Get-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ServerAdminUI'
    $result | Should -Be 0
  }

  It 'prefix: HKCU\' {
    $result = Get-RegValue -FullPath 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ServerAdminUI'
    $result | Should -Be 0
  }

  It 'prefix: HKCU:\' {
    $result = Get-RegValue -FullPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ServerAdminUI'
    $result | Should -Be 0
  }

  It 'ErrorAction: Stop' {
    { Get-RegValue -FullPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Stop\inexistent' -ErrorAction Stop } | Should -Throw
  }

  It 'ErrorAction: SilentlyContinue' {
    $result = Get-RegValue -FullPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SilentlyContinue\inexistent' -ErrorAction SilentlyContinue
    $result | Should -BeNullOrEmpty
  }

  It 'ErrorAction: Continue' {
    $result = Get-RegValue -FullPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Continue\inexistent' -ErrorAction Continue
    $result | Should -BeNullOrEmpty
  }
}
