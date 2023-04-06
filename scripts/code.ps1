<#
.VERSION 20230406

.SYNOPSIS
Loader for VS Code that looks up the real path if the target is a substed folder.
The location of this script should be in %PATH%, and above the location of VS Code.
This script is needed because of a bug in VS code, where the git gutters are not displayed correctly on symlinked and substed locations.
https://github.com/microsoft/vscode/issues/100274

.EXAMPLE
```
code.ps1

code .

code n:\src\repo1
```
#>

Write-Output "Starting VS Code loader.."

. "$PSScriptRoot/../ps-winhelpers/_PS-WinHelpers.ps1"

$RealRoot = Get-RealPath $PSScriptRoot

$Paths = $env:Path -split ';'

# Remove the current script's location from %PATH%, so we can call the real `code.cmd` script
$NewPaths = Compare-Object -ReferenceObject $paths -DifferenceObject @($PSScriptRoot,$RealRoot) | where SideIndicator -eq '<=' | Select -ExpandProperty InputObject

$env:PATH = $NewPaths -join ';'

# Get the real path of the target
$dst = Get-RealPath $args[0]
code $dst

Refresh-Path | Out-Null
