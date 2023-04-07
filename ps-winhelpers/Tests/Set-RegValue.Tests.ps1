BeforeAll {
  $DebugPreference = 'Continue'
  $InformationPreference = 'Continue'
  $VerbosePreference = 'Continue'
  
  . "$PSScriptRoot\..\..\ps-winhelpers\_PS-WinHelpers.ps1"  
}

BeforeDiscovery {
  $TypeTests = @(
    @{ Name = 'DWordMin'; RegType = 'DWord'; ValType = 'int32'; Value = (Get-Random -Maximum 65535) }
    @{ Name = 'DWordMax'; RegType = 'DWord'; ValType = 'uint32'; Value = [uint32](Get-Random -Minimum 2147483649 -Maximum 4294967295) }
    @{ Name = 'REG_DWORD_Min'; RegType = 'REG_DWORD'; ValType = 'int32'; Value = (Get-Random -Maximum 65535) }
    @{ Name = 'REG_DWORD_Max'; RegType = 'REG_DWORD'; ValType = 'uint32'; Value = [uint32](Get-Random -Minimum 2147483649 -Maximum 4294967295) }

    @{ Name = 'QWordMin'; RegType = 'QWord'; ValType = 'int64'; Value = (Get-Random -Maximum 4294967295) }
    @{ Name = 'QWordMax'; RegType = 'QWord'; ValType = 'uint64'; Value = [uint64](Get-Random -Minimum 9223372032559808513 -Maximum 18446744065119617025) }
    @{ Name = 'REG_QWORD_Min'; RegType = 'REG_QWORD'; ValType = 'int64'; Value = (Get-Random -Maximum 4294967295) }
    @{ Name = 'REG_QWORD_Max'; RegType = 'REG_QWORD'; ValType = 'uint64'; Value = [uint64](Get-Random -Minimum 9223372032559808513 -Maximum 18446744065119617025) }

    @{ Name = 'String'; RegType = 'String'; ValType = 'string'; Value = (New-Guid).GUID }
    @{ Name = 'REG_SZ'; RegType = 'REG_SZ'; ValType = 'string'; Value = (New-Guid).GUID }

    @{ Name = 'MultiString'; RegType = 'MultiString'; ValType = 'string[]'; Value = 'Hello123', 'World123' }
    @{ Name = 'REG_MULTI_SZ'; RegType = 'REG_MULTI_SZ'; ValType = 'string[]'; Value = 'Hello', 'World' }

    # @{ Name = 'REG_BINARY'; RegType = 'REG_BINARY'; ValType = '???'; Value = '101' } # Not implemented
  )
}

Describe 'Create Registry Values' {
  BeforeAll {
    $GUID = (New-Guid).Guid
    $RegRoot = "HKEY_CURRENT_USER\SOFTWARE\Pester\$GUID"
    Write-Debug "RegRoot is: $RegRoot"
  }

  Context 'Create <_.RegType> = <_.Value>' -ForEach $TypeTests {
    BeforeAll {
      $action = Set-RegValue -FullPath "$RegRoot\Test-${Name}" -Value $Value -Type $RegType -Force
      $result = Get-ItemPropertyValue -Path ($RegRoot -replace 'HKEY_CURRENT_USER\\', 'HKCU:\') -Name "Test-${Name}"
    }

    It 'Should be of type: <RegType>' {
      $result.GetType().Name | Should -Be $ValType
    }

    It 'Should have value: <Value>' {
      $result | Should -Be $Value
    }
  }

  Context 'Create <_> = "Hello, <env:USERNAME>!"' -ForEach @('ExpandString', 'REG_EXPAND_SZ') {
    BeforeAll {
      $action = Set-RegValue -FullPath "$RegRoot\Test-$_" -Value 'Hello, %USERNAME%!' -Type $_ -Force
      $result = Get-ItemPropertyValue -Path ($RegRoot -replace 'HKEY_CURRENT_USER\\', 'HKCU:\') -Name "Test-$_"
    }

    It 'Should be of type: <_>' {
      $result.GetType().Name | Should -Be 'string'
    }

    It 'Should have value: "Hello, <env:USERNAME>!"' {
      $result | Should -Be "Hello, $env:USERNAME!"
    }
  }

  Context 'Testing root variation: <_>' -ForEach 'HKEY_CURRENT_USER\', 'HKCU\', 'HKCU:\', 'HKEY_CURRENT_USER:\' {
    BeforeAll {
      $Value = Get-Random -Minimum 2147483649 -Maximum 4294967295
      $RegRootTest = $RegRoot -replace 'HKEY_CURRENT_USER\\', $_
      $TestName = $_ -replace '\\', '_'
      $action = Set-RegValue -FullPath "$RegRootTest\Test-$TestName" -Value $Value -Type 'DWord' -Force
      $result = Get-ItemPropertyValue -Path ($RegRoot -replace 'HKEY_CURRENT_USER\\', 'HKCU:\') -Name "Test-$TestName"
    }

    It 'Should be of type: DWORD' {
      $result.GetType().Name | Should -Be 'uint32'
    }

    It 'Should have value: <Value>' {
      $result | Should -Be $Value
    }
  }

  AfterAll {
    # Remove-Item -Recurse -Force -Path ($RegRoot -replace 'HKEY_CURRENT_USER\\', 'HKCU:\')
  }
}
