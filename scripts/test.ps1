. "$(Split-Path $MyInvocation.MyCommand.Source -Parent)/../ps-winhelpers/_PS-WinHelpers.ps1"
function Get-ScriptPath22 {
  <#
  .SYNOPSIS
  Returns the full path to the powershell running script.

  .EXAMPLE
  Write-Host "Script path: $(Get-ScriptPath)"
  #>

  Get-PSCallStack
  return "Path: $($MyInvocation)"
}


Get-ScriptPath

Get-EnvPathsArr


$MyInvocation.MyCommand.Source

