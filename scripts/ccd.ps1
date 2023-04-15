<#PSScriptInfo
.VERSION      2023.04.15
.AUTHOR       Levente Rog
.COPYRIGHT    (c) 2023 Levente Rog
.LICENSEURI   https://github.com/levid0s/useful/blob/master/LICENSE.md
.PROJECTURI   https://github.com/levid0s/useful/
#>

<#
.SYNOPSIS
Open a folder browser dialog and changes the current directory to the selected folder.

.EXAMPLE
ccd
# do stuff...
popd

.EXAMPLE
# Specify starting directory
ccd d:\
"d:\" | ccd

# Don't change dir, just return the selected path
$selectedPath = ccd -PassThru
$selectedPath = get-item c:\ | ccd -PassThru
#>

[CmdletBinding()]
param(
  [Parameter(ValueFromPipeline = $true)][string]$Path,
  [switch]$PassThru
)

if (!$Path) {
  $Path = $pwd.Path
}

[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null
$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.Description = 'Select a folder'
$foldername.rootfolder = 'MyComputer'
$foldername.SelectedPath = $Path

if ($foldername.ShowDialog() -ne 'OK') {
  return
}

if ($PassThru) {
  return $foldername.SelectedPath
}

Push-Location $foldername.SelectedPath
