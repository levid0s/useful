<#PSScriptInfo
.VERSION      2024.06.09
.AUTHOR       Levente Rog
.COPYRIGHT    (c) 2024 Levente Rog
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

function Update-EnvironmentVariable ($key, $newValue) {
    $currentValue = [System.Environment]::GetEnvironmentVariable($key, [EnvironmentVariableTarget]::Process)
    if ($newValue -ne $currentValue) {
        Write-Output "Updated: ${key}: $currentValue -> $newValue"
        [System.Environment]::SetEnvironmentVariable($key, $newValue, [EnvironmentVariableTarget]::Process)
    }
}

$SkipKeys = @("Path", "Username", "PSModulePath", "PATHEXT")

$envs = @{}


$e = [Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Machine)

$e.GetEnumerator() | Where-Object { $_.Key -notin $SkipKeys } | ForEach-Object { $envs[$_.Key] = $_.Value }

$e = [Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::User)

$e.GetEnumerator() | ? {$_.Key -notin $SkipKeys } | ForEach-Object { $envs[$_.Key] = $_.Value }


foreach ($key in $envs.Keys) {
    Update-EnvironmentVariable -key $key -newValue $envs[$key]
}
