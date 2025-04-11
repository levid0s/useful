[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [System.Collections.ArrayList]$listArgs = @()
)

<#
.VERSION 2025.04.09

.SYNOPSIS
Resolves the path of $args[-1] if it's on a substed drive, so that Git Gutters will work properly in VS Code.
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

Write-Host "[$($MyInvocation.MyCommand.Path)] Starting VS Code loader .."

. "$PSScriptRoot/../ps-winhelpers/_PS-WinHelpers.ps1"

if ($listArgs.Count -eq 0) {
    Write-Verbose "No args provided, using [git_root]`$PWD."
    $listArgs += $PWD.Path
}

$LastArg = $listArgs[-1]
Write-Verbose "Last arg is: ``$LastArg``"

if ($LastArg -notmatch '^-') {
    Write-Verbose "Last arg is not switch, checking if it's folder."

    if ((Get-Item $LastArg -ErrorAction SilentlyContinue).PSIsContainer -eq $true) {
        Write-Verbose "Last arg is folder, looking up git root."
        $Location = Get-RealGitRoot $LastArg -ResolveSubst:$False | Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
        $listArgs[-1] = $Location
    }
    else {
        Write-Verbose "Last arg is file or doesn't exist, no lookup needed"
    }
}

Write-Host "[$($MyInvocation.MyCommand.Path)] EXEC: code.cmd $listArgs"
code.cmd $listArgs

New-Alias code. code