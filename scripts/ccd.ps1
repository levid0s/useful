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
    [switch]$PassThru,
    [switch]$FileBrowser,
    [switch]$Relative
)

if (!$Path) {
    $Path = $pwd.Path

    if ($FileBrowser) {
        $IsDir = Test-Path -Path $path -PathType Container
        if ($IsDir) {
            $Path = $Path + "\."
        }
    }
}

[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null

Write-Output "Path: $PATH"
if (!$FileBrowser) {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Select a folder'
    $dialog.rootfolder = 'MyComputer'
    $dialog.SelectedPath = $Path
}
else {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Select a File or Folder'
    $dialog.InitialDirectory = $Path
    $dialog.Filter = 'All files (*.*)|*.*'
    $dialog.CheckFileExists = $false
    $dialog.CheckPathExists = $true
    $dialog.DereferenceLinks = $true
    $dialog.ValidateNames = $false
    $dialog.ShowReadOnly = $true
    $dialog.FileName = $Path
}

$response = $dialog.ShowDialog()

if ($response -ne 'OK') {
    return
}

if (!$FileBrowser) {
    $result = $dialog.SelectedPath
}
else {
    $result = $dialog.FileName
}

if ($Relative) {
    $result = Resolve-Path -Path $result -Relative
}


if ($PassThru) {
    return $result
}


if (!$FileBrowser) {
    Push-Location $result
}
else {
    Write-Output "Opening: $result"
    & $result
}
