<#
.SYNOPSIS
Refresh the %PATH% in current shell to whatever is set in the Registry.
Useful when new apps were installed and you don't want to close your shell.

.EXAMPLE
Refresh-Path.ps1
#>

function Get-EnvPathsArr {
	[OutputType([String[]])]  

	Param(
		[ValidateSet('User', 'Machine', 'All')]
		$Scope = 'All'
	)	
	
	$Paths = @()
	
	if ( @('Machine', 'All') -icontains $Scope) {
		$Paths += `
			[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
	}
	
	if ( @('User', 'All') -icontains $Scope) {
		$Paths += `
			[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
	}
	
	return $Paths
}


###
###  Refresh Shell
###

$pathsRegistry = $(Get-EnvPathsArr) -join ';'

if ($pathsRegistry -ne $env:Path) {
	Write-Output "${actionVerb}: Refreshing %PATH% in current shell..."		
	$env:Path = $(Get-EnvPathsArr) -join ';'
}
else {
	Write-Output "${actionVerb}: %PATH% already up to date."
}

Write-Output ''
