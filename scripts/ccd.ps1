<#PSScriptInfo
.VERSION      2023.03.22
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
#>

[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.Description = "Select a folder"
$foldername.rootfolder = "MyComputer"
$foldername.SelectedPath = $pwd.Path

if ($foldername.ShowDialog() -eq "OK") {
  Push-Location $foldername.SelectedPath
}
