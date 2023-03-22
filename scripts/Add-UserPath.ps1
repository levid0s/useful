<#
.SYNOPSIS
Adds an additional path to the USER scoped %PATH% environment variable, and refreshes the current shell.
.DESCRIPTION
✓ Adds a path to the user's PATH environment variable.
✓ Path is resolved before adding
.EXAMPLE
Add-UserPath.ps1 -Path 'C:\Program Files\Git\cmd'
#>

param(
	[Parameter(Mandatory = $true)][string]$Path
)

."$(Split-Path $MyInvocation.MyCommand.Source -Parent)/../ps-winhelpers/_PS-WinHelpers.ps1"
$()

###
#Region: Helper Functions
###

function Get-EnvPathsArr {
	<#
  .SYNOPSIS
  Get the PATH environment variable as an array. Can get either the User or Machine scope, or both.

  .PARAMETER Scope
  The scope of the PATH variable to get. Can be 'User', 'Machine' or 'All'.

  .EXAMPLE
  Get-EnvPathsArr

  .EXAMPLE
  Get-EnvPathsArr -Scope User
  #>

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

function Add-UserPaths {
	<#
  .SYNOPSIS
  Adds additional paths to the USER scope %PATH% environment variable.

  .DESCRIPTION
  ✓ Adds a list of paths to the user's PATH environment variable.
  ✓ It doesn't remove or overwrite the existing paths (unlike [Environment]::SetEnvironmentVariable or setting $env:PATH)
  ✓ Duplicate paths are automatically ignored.

  .PARAMETER Paths
  Array of strings representing paths to add to the user's %PATH% environment variable.

  .EXAMPLE
  Add-UserPaths -Paths 'C:\Program Files\Git\cmd', 'C:\Program Files\Git\usr\bin'

  .TODO
  - Add support for Machine scope
  #>

	param(
		[string[]]$Paths
	)

	[String[]]$existingPathsUser = Get-EnvPathsArr('User')

	$NewPathsDiff = Compare-Object -ReferenceObject $existingPathsUser -DifferenceObject $Paths | `
		Where-Object SideIndicator -eq '=>' | `
		Select-Object -ExpandProperty InputObject

	if ($NewPathsDiff.Count -eq 0) {
		Write-DebugLog "Paths ``$Paths`` already present, no changes needed."    
		return
	}

	$newEnvTargetUser = ($existingPathsUser + $NewPathsDiff) -join ';'

	if (${Dry-Run} -eq $true) {
		Write-Verbose "DRY-RUN: Setting User PATH to $newEnvTargetUser"
	}
	else {
		Write-DebugLog "Adding the following paths to user %PATH%:`n- $($NewPathsDiff -join "`n- ")`n"
		[Environment]::SetEnvironmentVariable("Path", "$newEnvTargetUser", [System.EnvironmentVariableTarget]::User)
	}
}

function Update-PathsInShell {
	<#
  .SYNOPSIS
  Refresh the PATH environment variable in the current shell.

  .DESCRIPTION
  Useful when new apps were installed and you don't want to close your shell.
  Also useful after running `Add-UserPaths` or `Remove-UserPaths`.
  This function uses Write-DebugLog.
  For a standalone version see `useful/scripts/Refresh-Path.ps1`
  
  .EXAMPLE
  Update-PathsInShell
  #>

	$pathsInRegistry = Get-EnvPathsArr -Scope All
	$pathsInShell = $env:PATH -split ';'

	$diff = Compare-Object -ReferenceObject $pathsInRegistry -DifferenceObject $pathsInShell

	if (!$diff) {
		Write-DebugLog "%PATH% in shell already up to date."
		return
	}

	Write-DebugLog "Updates to %PATH% detected:`n`n $($diff | Out-String) `n"
	Write-DebugLog "Refreshing %PATH% in current shell.."
	$env:Path = $pathsInRegistry -join ';'
}

function Write-DebugLog {
	<#
  .SYNOPSIS
  Script for writing debug messages to the console, with additional information like the function name.

  .DESCRIPTION
  ✓ Function name automatically added to the message.
  ✓ Output is padded based on the depth of the call.
  ✓ Control the level of debug information presented using the $DEBUGDEPTH global variable.
  ✓ Uses `Write-Debug`, so make sure: $DebugPreference='Continue'

  .EXAMPLE
  Write-DebugLog "Hello World"
  
  .Example_output
  # DEBUG: >> [ Invoke-Something ]: Running task `assocs` for Somethiing : System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable
  # DEBUG: >>>> [ Update-FileAssocsExt ]: Creating assoc for jpg -> `N:\Tools\FSViewer\FSViewer.exe` : ``
  # DEBUG: >>>>>> [ Test-Function ]: Hello, world!
  #>

	param(
		[string]$Message
	)

	$Caller = (Get-PSCallStack)[1].Command

	# Get depth of call. 0 = main script, 1 = Helper ps1 , 2 = Write-DebugLog. Level any negative value to 0
	$Depth = 0, ((Get-PSCallStack).Count - 3) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum  # Main script is 0
  
	if (!$DEBUGDEPTH) {
		# Default value, if not already set via a global var
		$DEBUGDEPTH = 2
	}

	if ($Depth -gt $DEBUGDEPTH) { return }
	if (!$DEBUGDEPTH) { $MaxDepth = 4 * 2 }
	else { $MaxDepth = $DEBUGDEPTH * 2 }

	$FrontPadChar = '>'
	$FrontPadVal = $Depth * 2
	$FrontPadding = $FrontPadChar * $FrontPadVal
	# $FrontPadding = $FrontPadding.PadRight($MaxDepth, ' ')
	$MidPadChar = '>'
	$MidPadVal = $Depth * 0
	$MidPadding = $MidPadChar * $MidPadVal + ' ' * [math]::Sign($MidPadVal)

	Write-Debug "${FrontPadding} [ ${Caller} ]: ${MidPadding}${Message}"
}

###
#Endregion
###

$PreviousDebugPreference = $DebugPreference
$DebugPreference = 'Continue'

try {
	$FullPath = Resolve-Path -Path $Path
}
catch {
	# Throw error
	Throw "Path ``$Path`` does not exist."
}

Write-DebugLog "Path ``$Path`` resolved to ``$FullPath``"

Add-UserPaths -Paths $FullPath
Update-PathsInShell

$DebugPreference = $PreviousDebugPreference
