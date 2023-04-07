<#
.VERSION 20230406

.SYNOPSIS
Resolves the path of $args[0] if it's on a substed drive, so that Git Gutters will work properly in VS Code.
Opens VS Code in the Git root if it's a git folder

.DESCRIPTION
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

Write-Output 'Starting VS Code loader..'

. "$PSScriptRoot/../ps-winhelpers/_PS-WinHelpers.ps1"

$Location = $args[0]
if ([string]::IsNullOrEmpty($Location)) {
  $Location = $PWD.Path
}
# Get the real path of the target
$dst = Get-RealGitRoot $Location

Write-Debug "Real path is: $dst"

code.cmd $dst

Refresh-Path | Out-Null
