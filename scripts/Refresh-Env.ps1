<#PSScriptInfo
.VERSION      2025.04.12
.AUTHOR       Levente Rog
.COPYRIGHT    (c) 2025 Levente Rog
.LICENSEURI   https://github.com/levid0s/useful/blob/master/LICENSE.md
.PROJECTURI   https://github.com/levid0s/useful/
#>

<#
.SYNOPSIS
Refresh the envs in current shell to the state configured in Registry / System settings.
Useful when new apps have been installed and you don't want to close your shell.

.EXAMPLE
Refresh-Env.ps1
#>

[CmdletBinding()]
param()

function Get-EnvironmentVariableNames([System.EnvironmentVariableTarget] $Scope) {
    <#
    .SYNOPSIS
    Gets all environment variable names.
    
    .DESCRIPTION
    Provides a list of environment variable names based on the scope. This
    can be used to loop through the list and generate names.
    
    .OUTPUTS
    List of environment variables names: [string[]]
    
    .PARAMETER Scope
    The environment variable target scope. This is `Process`, `User`, or `Machine`.
    
    .EXAMPLE
    Get-EnvironmentVariableNames -Scope Machine    
    #>
    
    switch ($Scope) {
        'User' { Get-Item 'HKCU:\Environment' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property }
        'Machine' { Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' | Select-Object -ExpandProperty Property }
        'Process' { Get-ChildItem Env:\ | Select-Object -ExpandProperty Key }
        default { throw "Unsupported environment scope: $Scope" }
    }
}
  
# Filter out Machine envs where a User env with the same name overrides it
$UserEnvs = Get-EnvironmentVariableNames -Scope User

Get-EnvironmentVariableNames -Scope Machine | ? { $_ -ine 'Path' -and $_ -inotin $UserEnvs } | % {
    $CurrentValue = Get-Item "env:$_" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    $NewValue = [Environment]::GetEnvironmentVariable($_, [EnvironmentVariableTarget]::Machine)
    Write-Verbose "Checking: $_= $CurrentValue -> $NewValue"
    if ($CurrentValue -ne $NewValue) {
        Write-Information -InformationAction Continue "Updating: $_=`"$NewValue`""
        Set-Item -Path "env:$_" -Value $NewValue
    }
}

Get-EnvironmentVariableNames -Scope User | ? { $_ -ine 'Path' } | % {
    $CurrentValue = Get-Item "env:$_" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
    $NewValue = [Environment]::GetEnvironmentVariable($_, [EnvironmentVariableTarget]::User)
    Write-Verbose "Checking: $_= $CurrentValue -> $NewValue"

    if ($CurrentValue -ne $NewValue) {
        Write-Information -InformationAction Continue "Updating: ${_}: `"$CurrentValue`" -> `"$NewValue`""
        Set-Item -Path "env:$_" -Value $NewValue
    }
}

$NewPaths = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) + ";" + [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
$NewPaths = $NewPaths -replace ';;', ';'
if ($env:PATH -ne $NewPaths) {
    Write-Information -InformationAction Continue "Updating: PATH:`n$env:PATH ->`n$NewPaths"
    $env:PATH = $NewPaths
}
