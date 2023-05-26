<#PSScriptInfo
.VERSION      2023.03.22
.AUTHOR       Levente Rog
.COPYRIGHT    (c) 2023 Levente Rog
.LICENSEURI   https://github.com/levid0s/useful/blob/master/LICENSE.md
.PROJECTURI   https://github.com/levid0s/useful/
#>

<#
.SYNOPSIS
A collection of PowerShell functions for common tasks.

.EXAMPLE
. ./_PS-WinHelpers.ps1
Write-Host "PowerShell script path: $(Get-ScriptPath)"
Write-Host "Running as admin: $(IsAdmin)"
Create-Shortcut -TargetPath 'C:\Windows\System32\cmd.exe' -ShortcutPath 'C:\Users\Public\Desktop\cmd.lnk' -Arguments '/k "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"'
#>

###
###  PowerShell Scripting Helpers
###

function IsAdmin {
  <#
  .SYNOPSIS
  Returns $True if the script is running with elevated privileges

  .EXAMPLE
  if (IsAdmin) { Write-Host "Running as admin" }
  #>

  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)  
}

function Invoke-ToAdmin {
  <#
  .VERSION 2023.04.29

  .SYNOPSIS
  Elevates the current PowerShell script to admin privileges.
  If UAC is enbled, the user will get a UAC prompt.

  .EXAMPLE
  if(!IsAdmin) {
    Invoke-ToAdmin; Return 
  }
  else {
    Write-Host "Doing stuff as admin."
  }

  .TODO
  - Add support for setting the working directory, as the -WorkingDirectory parameter is not working.
  #>

  param(
    [hashtable]$CustomArguments = @{}
  )

  If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-DebugLog 'Already admin, nothing to do.'
    Return
  }

  $PsCmd = (Get-ChildItem -Path "$PSHome\pwsh*.exe", "$PSHome\powershell*.exe")[0]

  Write-Information 'Elevating script to Admin..'

  $ScriptPath = (Get-PSCallStack)[1].ScriptName
  $ScriptDir = (Get-PSCallStack)[1].ScriptName | Split-Path -Parent


  $ArgHashtable = @{}

  $ArgumentsString = (Get-PSCallStack)[1].Arguments.TrimStart('{').TrimEnd('}')

  foreach ($a in ($ArgumentsString -split ',\s*')) {
    $k, $v = $a -split '\s*=\s*'
    if ($k -eq 'InvokeToAdmin') { continue }
    $ArgHashtable[$k] = $v
  }

  # Overwrite any arguments with custom ones
  foreach ($k in $CustomArguments.Keys) {
    $ArgHashtable[$k] = $CustomArguments[$k]
  }

  # Build the $ArgumentList string
  $cmd = Get-Command $ScriptPath
  $params = $cmd.Parameters

  $ArgumentList = @('-File', $ScriptPath)
  foreach ($k in $ArgHashtable.Keys) {
    $v = $ArgHashtable[$k]
    switch ($params[$k].ParameterType) {
      'bool' { 
        $ArgumentList += "-${k}"
        $v = $v -in @('true', $true)
        $ArgumentList += '$' + $v.ToString().ToLower()
      }
      'switch' {
        if ($v -in @('true', $true)) {
          $ArgumentList += "-${k}"
        }
      }
      default {
        $ArgumentList += "-${k}"
        if ($null -eq $v) {
          $v = '$null'
        }
        $ArgumentList += $v
      }
    }
  }

  Write-Debug "ScriptPath: $ScriptPath"
  Write-Debug "ScriptDir: $ScriptDir"
  Write-Debug "Arguments: $(Expand-Hashtable $ArgumentList)"
  
  Write-DebugLog "Start-Process $PsCmd -Verb runAs -ArgumentList $(Expand-Hashtable $ArgumentList) -WorkingDirectory $ScriptDir"
  
  # -Verb runAs `
  Start-Process "$PsCmd" `
    -Verb runAs `
    -ArgumentList $ArgumentList `
    -WorkingDirectory $ScriptDir
}

function Install-ModuleIfNotPresent {
  <#
  .SYNOPSIS
  Install a module if it is not already present

  .EXAMPLE
  Install-ModuleIfNotPresent 'PowerShell-YAML'
  #>

  param(
    [string]$ModuleName,
    [ValidateSet('AllUsers', 'CurrentUser')][string]$Scope = 'CurrentUser'
  )

  if (!(Get-Module $ModuleName -ListAvailable -ErrorAction SilentlyContinue)) {
    Install-Module $ModuleName -Scope $Scope
  }
}

function Get-ScriptPath {
  <#
  .SYNOPSIS
  Returns the full path to the powershell running script.

  .EXAMPLE
  Write-Host "Script path: $(Get-ScriptPath)"
  #>

  return (Get-PSCallStack)[1].ScriptName | Split-Path -Parent
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
    [string]$Message,
    [string]$LogLevel = 'DEBUG',
    [string]$Header = 'Data'
  )

  $Caller = (Get-PSCallStack)[1].Command

  # Get depth of call. 0 = main script, 1 = Helper ps1 , 2 = Write-DebugLog. Level any negative value to 0
  $Depth = 0, ((Get-PSCallStack).Count - 3) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum  # Main script is 0
  
  if ($null -eq $DEBUGDEPTH) {
    # Default value, if not already set via a global var
    $DEBUGDEPTH = 2
  }

  if ($Depth -gt $DEBUGDEPTH -and $LogLevel -in @('VERBOSE', 'DEBUG')) { return }
  if (!$DEBUGDEPTH) { $MaxDepth = 4 * 2 }
  else { $MaxDepth = $DEBUGDEPTH * 2 }

  $FrontPadChar = '>'
  $FrontPadVal = $Depth * 2
  $FrontPadding = $FrontPadChar * $FrontPadVal + ' ' * [math]::Sign($FrontPadVal)
  # $FrontPadding = $FrontPadding.PadRight($MaxDepth, ' ')
  $MidPadChar = '>'
  $MidPadVal = $Depth * 0
  $MidPadding = $MidPadChar * $MidPadVal + ' ' * [math]::Sign($MidPadVal)

  switch ($LogLevel) {
    'VERBOSE' { 
      if ($Message -match '\r\n|\n|\r') {
        # Multiline message
        Write-Verbose "${FrontPadding}[ ${Caller} ]:`n======================== Start of $Header =====================`n${Message}========================= End of $Header ======================"
      }
      else {
        Write-Verbose "${FrontPadding}[ ${Caller} ]: ${MidPadding}${Message}"
      }
    }
    'DEBUG' { Write-Debug "${FrontPadding}[ ${Caller} ]: ${MidPadding}${Message}" }
    'INFO' { 
      # Workaround for https://stackoverflow.com/questions/55191548/write-information-does-not-show-in-a-file-transcribed-by-start-transcript
      # InformationPreference should be = ??
      Write-Information "${FrontPadding}[ ${Caller} ]: ${MidPadding}${Message}" 
      [System.Console]::WriteLine("INFO: ${FrontPadding}[ ${Caller} ]: ${MidPadding}${Message}")
    }
    'WARN' { Write-Warning "${FrontPadding}[ ${Caller} ]: ${MidPadding}${Message}" }
    'ERROR' { Write-Error "${FrontPadding}[ ${Caller} ]: ${MidPadding}${Message}" -ErrorAction Continue }
    default { throw 'Unknown Log Level.' }
  }
  
}

function Start-SleepOrKey {
  <#
  .VERSION 20230322

  .SYNOPSIS
  Similar to Start-Sleep, but sleep is cancelled on any keypress.

  .EXAMPLE
  do {
    Write-Host "Doing stuff..."
    $key = Start-SleepOrKey -Seconds 10
    if ($key.Character -eq 'q' ) {
      Write-Host "Quitting.."
      break
    }
  } while ($true)
  
  #>

  param(
    [int]$Seconds
  )
  $key = $null
  $startTime = Get-Date
  while (((Get-Date) - $startTime) -lt [TimeSpan]::FromSeconds($Seconds)) {
    if ($Host.UI.RawUI.KeyAvailable) {
      $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
      return $key
    }
    Start-Sleep -Milliseconds 100  # Wait for 100 milliseconds before checking again
  }
}

function Start-SleepUntilTrue {
  <#
  .VERSION 20230330

  .SYNOPSIS
  Pause execution until a condition is met or a timeout is reache
  
  .DESCRIPTION
  The condition is considered met, once the scriptblock returns a value that is different from `$null` or `$false`.
  Function passes through the result of `{ Condition }`, so it can be used in a variable assignment.

  .EXAMPLE
  $result = Start-SleepUntilTrue -Condition { Get-Process -Name "notepad" } -Seconds 10

  #>

  param(
    [ScriptBlock]$Condition,
    [int]$Seconds = 5
  )
  $startTime = Get-Date
  $result = & $Condition
  while (!(((Get-Date) - $startTime) -gt [TimeSpan]::FromSeconds($Seconds) -or $result)) {
    Start-Sleep -Milliseconds 300
    $result = & $Condition
  }
  return $result
}

Function Start-SleepUntilTrueEx {
  <#
  .VERSION 20230415

  .SYNOPSIS
  A more advanced version of Start-SleepUntilTrue, with exponential backoff and a check condition.

  .DESCRIPTION
  The function keeps executing the code from the Do and Check scriptblocks, until the a condition is considered met, as follows:
  - If a Check block was provided, success depends if the Check block returns `$true`.
  - If no Check block was provided, success depends if the Do block returns a value that is different from `$null` or `$false`.
  - If the timeout has been reached, the function returns `$false`.
  TODO: Output

  .PARAMETER ExponentialBackoff
  If set, the delay between each round will be doubled.

  .PARAMETER MaxTimeoutMs
  Maximum timeout in milliseconds.
  If this is set, the function will exit when the timeout is reached, even if the total number of rounds have not been completed.

  .EXAMPLE
  # Wait for the notepad process to start
  Start-SleepUntilTrueEx `
    -Do {
      Get-Process notepad -ErrorAction SilentlyContinue
    }

  .EXAMPLE
  # Poll creating a user until it's successful, with exponential backoff.
  Start-SleepUntilTrueEx `
    -InitialDelayMs 1000 `
    -ExponentialBackoff `
    -Do {
      curl.exe -X POST 'https://example.com/api/create-user' --data-raw '{ "username": "johndoe", "email": "johndoe@example.com", "password": "secretpassword"}'
    } `
    -Check {
      curl.exe 'https://example.com/api/user?id=johndoe'
    }
  #>

  param(
    [int]$Rounds = 5,
    [int]$InitialDelayMs = 100,
    [int]$MaxTimeoutMs,
    [switch]$ExponentialBackoff,
    [scriptblock]$Do = {},
    [scriptblock]$Check = {}
  )

  $CheckResult = $null
  $startTime = Get-Date

  for ($round = 1; $round -le $rounds; $round++) {
    if ($round -gt 1) {
      Write-Verbose "Check condition not met, retrying with exponential backoff, round $round. Sleeping for $InitialDelayMs ms.."
      Start-Sleep -Milliseconds $InitialDelayMs
      if ($ExponentialBackoff) {
        $InitialDelayMs *= 2
      }
    }
    if ($MaxTimeoutMs) {
      $elapsedTime = (Get-Date) - $startTime
      if ($elapsedTime.TotalMilliseconds -gt $MaxTimeoutMs) {
        Throw "Check condition not met after $Rounds rounds. Timeout reached."
      }
    }
    try {
      $DoResult = & $Do
      $DoSuccess = $true
    }
    catch {
      $DoSuccess = $false
    }

    # If a Check block was provided, success depends if the Check block returns $true.
    if ($Check.ToString()) {
      $CheckResult = & $Check
      if (!$CheckResult) {
        Continue
      }
    }
    else {
      # If no Check block was provided, success depends if the Do block doesn't throw an error.
      if (!$DoSuccess) {
        Continue
      }
    }

    Write-Verbose 'Check condition met, exiting loop.'
    return @{DoResult = $DoResult; CheckResult = $CheckResult }
  }
  Throw "Check condition not met after $Rounds rounds."
}

Function Get-SubstedPaths {
  <#
  .VERSION 20230406

  .SYNOPSIS
  Get a Hashtable of the currently Substed drives

  .EXAMPLE
  Get-SubstedPaths

  Name    Value
  ----    -----
  M:      D:\Dropbox\Music
  N:      D:\Dropbox
  
  #>

  $SubstOut = $(subst)
  $SubstedPaths = @{}
  $SubstOut | ForEach-Object { 
    $SubstedPaths[($_ -Split '\\: => ')[0]] = ($_ -Split '\\: => ')[1]
  }
  return $SubstedPaths
}

Function Get-RealPath {
  <#
  .VERSION 20230526

  .SYNOPSIS
  Returns the real path of a file or folder if the current path is on a substed drive

  .DESCRIPTION
  ✓ If path is a substed drive, it's resolved to the real location
  ✓ If path is a symlink or junction, it's resolved to the real location

  .EXAMPLE
  Get-RealPath
  Get-RealPath .
  Get-RealPath n:\tools
  #>

  param(
    [string]$Path
  )
  if ([string]::IsNullOrEmpty($Path)) {
    $Path = $PWD.Path
  }
  $Path = (Resolve-Path $Path).Path
  $SubstedPaths = Get-SubstedPaths
  if ($SubstedPaths.Keys -contains $Path.Substring(0, 2)) {
    $RealPath = $SubstedPaths[$Path.Substring(0, 2)] + $Path.Substring(2).TrimEnd('\')
  }
  else {
    $RealPath = $Path.TrimEnd('\')
  }
  $RealPath = Get-Item -Path $RealPath
  if ($RealPath.Target) {
    $RealPath = $RealPath.Target
  }
  else {
    $RealPath = $RealPath.FullName
  }
  return $RealPath
}

function Get-RealGitRoot {
  <#
  .VERSION 20230407

  .SYNOPSIS
  Returns the git root of a file or folder

  .DESCRIPTION
  ✓ If path is a substed drive, it's resolved to the real location
  ✓ If path is inside a git repo, it's resolved to the git root
  ✓ If path is pointing to a file, it's resolved to the parent directory

  .EXAMPLE
  Get-RealGitRoot .
  Get-RealGitRoot n:/src/useful/scripts
  #>

  param(
    [Parameter(Mandatory = $true)][string]$Location
  )

  $RealPath = Get-RealPath $Location
  if (Test-Path $RealPath) {
    $CheckPath = $RealPath
    if (!(Test-Path $CheckPath -Type Container)) {
      $CheckPath = Split-Path $RealPath -Parent
    }
    Write-Verbose "Check path is: $CheckPath"
    Push-Location $CheckPath
    $GitRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
      $GitRoot = $CheckPath
      Write-Verbose "Not a git repo. Keeping the real path: $CheckPath"
    }
    $RealPath = $GitRoot
    Pop-Location
  }
  
  Return $RealPath | Resolve-Path
}


Function Get-Timestamp {
  <#
  .VERSION 20230407
  #>
  return Get-Date -Format 'yyyyMMdd-HHmmss'
}

Function Get-ShortGUID {
  <#
  .VERSION 20230407
  #>
  return (New-Guid).Guid.Split('-')[0]
}

function Get-StringHash {
  <#
  .VERSION 20230415

  .SYNOPSIS
  Returns the hash of a string
  #>

  param(
    [Parameter(Mandatory = $true)][string]$String,
    [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')][string]$HashAlgorithm = 'SHA256'
  )

  $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($HashAlgorithm)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
  $hashBytes = $hasher.ComputeHash($bytes)
  return [System.BitConverter]::ToString($hashBytes) -replace '-'
}

###
###  Registry Manipulation Functions
###

function Get-RegValue {
  <#
  .VERSION 20230415

  .SYNOPSIS
  Reads a value from the registry

  .DESCRIPTION
  ✓ This is a simplified version of the Get-ItemPropertyValue function.
  ✓ No need to specify the Value Name and Path in separate parameters.
  ✓ Supports multiple namings for the HKCU and HKLM root keys for convenience.
  ‼ By design, backslash in Value Name is not supported

  .PARAMETER FullPath
  The full path to the registry value, including the Value Name.

  .PARAMETER ErrorAction
  The error action to use when the registry value does not exist. Set it to SilentyContinue to return $null instead of throwing an error.

  .EXAMPLE
  Get-RegValue -FullPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\Personal'

  .EXAMPLE
  Get-RegValue -FullPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\Personal' -ErrorAction SilentlyContinue
  #>

  [CmdletBinding()]
  param(
    [string]$FullPath
  )

  $ErrorAction = $PSBoundParameters['ErrorAction']
  if ([string]::IsNullOrEmpty($ErrorAction)) {
    Write-Verbose "Setting default value for ErrorAction: 'Stop'"
    $ErrorAction = 'Stop'
  }

  $Path = Split-Path $FullPath -Parent
  $Path = $Path -replace '^(HKCU|HKEY_CURRENT_USER|HKEY_CURRENT_USER:)\\', 'HKCU:\'
  $Path = $Path -replace '^(HKLM|HKEY_LOCAL_MACHINE|HKEY_LOCAL_MACHINE:)\\', 'HKLM:\'

  $Name = Split-Path $FullPath -Leaf

  # Get-ItemPropertyValue has a bug: https://github.com/PowerShell/PowerShell/issues/5906
  $Value = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction $ErrorAction | Select-Object -ExpandProperty $Name

  Return $Value
}

function Set-RegValue {
  <#
  .VERSION 20230429

  .SYNOPSIS
  Writes a value to the registry

  .DESCRIPTION
  A simplified and oppinionated version of the New-ItemProperty function:
  ✓ No need to specify Value Name and Path as separate parameters, just use FullPath="HKCU:\Path\To\Key\ValueName"
  ✓ Accepts various spellings of the `HKCU` and `HKLM` root keys for convenience.
  ✓ Autmatic data type detection for Value
  ✓ Auto-create the Path using the Force parameter
  ‼ By design, backslash in Value Name is not supported

  .PARAMETER FullPath
  The full path to the registry value, including the value name.
  For default values, use (Default)

  .PARAMETER Value
  The value to write to the registry. This parameter is of string[] type but type conversion is performed automatically for other value type (DWORD, etc.).

  .PARAMETER Type
  The Value's data type to be written. Supports both the .Net (String) and the registry (REG_SZ) names for convenience.

  .PARAMETER Force
  Create the registry key (including the full path) if it does not exist.

  .EXAMPLE
  Set-RegValue -FullPath 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer\DisableSearchBoxSuggestions' -Value 1 -Type DWord

  .EXAMPLE
  Set-RegValue -FullPath 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\MultiTaskingAltTabFilter' -Value 3 -Type REG_DWORD -Force

  #>

  param(
    [string]$FullPath,
    [object[]]$Value,
    [Parameter(Mandatory = $true)][ValidateSet('String', 'REG_SZ', 'MultiString', 'REG_MULTI_SZ', 'ExpandString', 'REG_EXPAND_SZ', 'DWord', 'REG_DWORD', 'QWord', 'REG_QWORD', 'Binary', 'REG_BINARY')][string]$Type,
    [switch]$Force
  )
  
  # Accept REG_* types for ease of use
  $LookupTable = @{
    'REG_SZ'        = 'String'
    'REG_EXPAND_SZ' = 'ExpandString'
    'REG_BINARY'    = 'Binary'
    'REG_DWORD'     = 'DWord'
    'REG_MULTI_SZ'  = 'MultiString'
    'REG_QWORD'     = 'QWord'
  }

  if ($LookupTable.ContainsKey($Type)) {
    $Type = $LookupTable[$Type]
  }

  $Path = Split-Path $FullPath -Parent
  $Path = $Path -replace '^(HKCU|HKEY_CURRENT_USER|HKEY_CURRENT_USER:)\\', 'HKCU:\'
  $Path = $Path -replace '^(HKLM|HKEY_LOCAL_MACHINE|HKEY_LOCAL_MACHINE:)\\', 'HKLM:\'

  $Name = Split-Path $FullPath -Leaf

  if ($Force) {
    if (!(Test-Path -LiteralPath $Path)) {
      New-Item -Path $Path -Force      
    }
  }

  switch -wildcard ($Type) {
    'String' { [string]$TargetValue = $Value }
    'ExpandString' { [string]$TargetValue = $Value }
    'MultiString' { [string[]]$TargetValue = $Value }
    'Binary' { [byte[]]$TargetValue = $Value }
    'DWord' { $TargetValue = [System.Convert]::ToUInt32($Value[0]) }
    'QWord' { $TargetValue = [System.Convert]::ToUInt64($Value[0]) }
  }
  
  $CheckValues = (Get-ItemProperty -LiteralPath $Path).PSObject.Properties
  if ($CheckValues.Name -contains $Name) {
    $SourceValue = $CheckValues[$Name].Value
    if ($null -in @($SourceValue, $TargetValue)) {
      # Special exception for $null because Compare-Object doesn't support it
      if ($SourceValue -eq $TargetValue) {
        Write-DebugLog "Value already set: $Path\$Name = `$null ($Type)" -LogLevel Verbose
        Return
      }
    }
    elseif (!(Compare-Object -DifferenceObject $SourceValue -ReferenceObject $TargetValue -SyncWindow 0)) {
      Write-DebugLog "Value already set: $Path\$Name = $TargetValue ($Type)" -LogLevel Verbose
      Return
    }
  }

  Write-DebugLog "Writing to registry: $Path\$Name = $TargetValue ($Type)"
  $result = New-ItemProperty -LiteralPath $Path -Name $Name -Value $TargetValue -PropertyType $Type -Force

  Return $result
}

###
###  Scheduled Tasks
###

function Register-PowerShellScheduledTask {
  <#
  .VERSION 20230407

  .SYNOPSIS
  Registers a PowerShell script as a **Hidden** Scheduled Task.
  At the moment the schedule frequency is hardcoded to every 15 minutes.

  .DESCRIPTION
  Currently, it's not possible create a hidden Scheduled Task that executes a PowerShell task.
  A command window will keep popping up every time the task is run.
  This function creates a wrapper vbs script that runs the PowerShell script as hidden.
  source: https://github.com/PowerShell/PowerShell/issues/3028

  .PARAMETER ScriptPath
  The path to the PowerShell script that will be executed in the task.

  .PARAMETER Parameters
  A hashtable of parameters to pass to the script.

  .PARAMETER TaskName
  The Scheduled Task will be registered under this name in the Task Scheduler.
  If not specified, the script name will be used.

  .PARAMETER AllowRunningOnBatteries
  Allows the task to run when the computer is on batteries.

  .PARAMETER Uninstall
  Unregister the Scheduled Task.

  .PARAMETER ExecutionTimeLimit
  The maximum amount of time the task is allowed to run.
  New-TimeSpan -Hours 72
  New-TimeSpan -Minutes 15
  New-TimeSpan -Seconds 30
  New-TimeSpan -Seconds 0 = Means disabled

  .PARAMETER AsAdmin
  Run the Scheduled Task as administrator.

  .PARAMETER GroupId
  The Scheduled Task will be registered under this group in the Task Scheduler.
  Eg: "BUILTIN\Administrators"

  .PARAMETER TimeInterval
  The Scheduled Task will be run every X minutes.

  .PARAMETER AtLogon
  The Scheduled Task will be run at user logon.

  .PARAMETER AtStartup
  The Scheduled Task will be run at system startup. Requires admin rights.
  #>

  param(
    [Parameter(Mandatory = $true, Position = 0)]$ScriptPath,
    [hashtable]$Parameters = @{},
    [string]$TaskName,
    [int]$TimeInterval,
    [switch]$AtLogon,
    [switch]$AtStartup,
    [bool]$AllowRunningOnBatteries,
    [switch]$DisallowHardTerminate,
    [TimeSpan]$ExecutionTimeLimit,
    [string]$GroupId,
    [switch]$AsAdmin,
    [switch]$Uninstall
  )

  if (!($TimeInterval -or $AtLogon -or $AtStartup -or $Uninstall)) {
    Throw 'At least one of the following parameters must be defined: -TimeInterval, -AtLogon, -AtStartup, (or -Uninstall)'
  }

  if ([string]::IsNullOrEmpty($TaskName)) {
    $TaskName = Split-Path $ScriptPath -Leaf
  }

  ## Uninstall
  if ($Uninstall) {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    # Return $true if no tasks found, otherwise $false
    return !(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)
  }

  ## Install
  if (!(Test-Path $ScriptPath)) {
    Throw "Script ``$ScriptPath`` not found!"
  }
  $ScriptPath = Resolve-Path -LiteralPath $ScriptPath

  # Create wrapper vbs script so we can run the PowerShell script as hidden
  # https://github.com/PowerShell/PowerShell/issues/3028
  if ($GroupId) {
    $vbsPath = "$env:ALLUSERSPROFILE\PsScheduledTasks\$TaskName.vbs"
  }
  else {
    $vbsPath = "$env:LOCALAPPDATA\PsScheduledTasks\$TaskName.vbs"
  }
  $vbsDir = Split-Path $vbsPath -Parent

  if (!(Test-Path $vbsDir)) {
    New-Item -ItemType Directory -Path $vbsDir
  }

  $ps = @(); $Parameters.GetEnumerator() | ForEach-Object { $ps += "-$($_.Name) $($_.Value)" }; $ps -join ' '
  $vbsScript = @"
Dim shell,command
command = "powershell.exe -nologo -File $ScriptPath $ps"
Set shell = CreateObject("WScript.Shell")
shell.Run command, 0, true
"@

  Set-Content -Path $vbsPath -Value $vbsScript -Force

  Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue -OutVariable TaskExists
  if ($TaskExists.State -eq 'Running') {
    Write-Debug "Stopping task for update: $TaskName"
    $TaskExists | Stop-ScheduledTask
  }
  $action = New-ScheduledTaskAction -Execute $vbsPath
  
  ## Schedule
  $triggers = @()
  if ($TimeInterval) {
    $t1 = New-ScheduledTaskTrigger -Daily -At 00:05
    $t2 = New-ScheduledTaskTrigger -Once -At 00:05 `
      -RepetitionInterval (New-TimeSpan -Minutes $TimeInterval) `
      -RepetitionDuration (New-TimeSpan -Hours 23 -Minutes 55)
    $t1.Repetition = $t2.Repetition
    $t1.Repetition.StopAtDurationEnd = $false
    $triggers += $t1
  }
  if ($AtLogOn) {
    $triggers += New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
  }
  if ($AtStartUp) {
    $triggers += New-ScheduledTaskTrigger -AtStartup
  }
    
  ## Additional Options
  $AdditionalOptions = @{}

  if ($AsAdmin) {
    $AdditionalOptions.RunLevel = 'Highest'
  }

  if ($GroupId) {
    $STPrin = New-ScheduledTaskPrincipal -GroupId $GroupId
    $AdditionalOptions.Principal = $STPrin
  }
  
  ## Settings 
  $AdditionalSettings = @{}

  if ($AllowRunningOnBatteries -eq $true) {
    $AdditionalSettings.AllowStartIfOnBatteries = $true
    $AdditionalSettings.DontStopIfGoingOnBatteries = $true
  }
  elseif ($AllowRunningOnBatteries -eq $false) {
    $AdditionalSettings.AllowStartIfOnBatteries = $false
    $AdditionalSettings.DontStopIfGoingOnBatteries = $false
  }

  if ($DisallowHardTerminate) {
    $AdditionalSettings.DisallowHardTerminate = $true
  }

  if ($ExecutionTimeLimit) {
    $AdditionalSettings.ExecutionTimeLimit = $ExecutionTimeLimit
  }


  $STSet = New-ScheduledTaskSettingsSet `
    -MultipleInstances IgnoreNew `
    @AdditionalSettings

  ## Decide if Register or Update
  if (!$TaskExists) {
    $cim = Register-ScheduledTask -Action $action -Trigger $triggers -TaskName $TaskName -Description "Scheduled Task for running $ScriptPath" -Settings $STSet @AdditionalOptions
  }
  else {
    $cim = Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggers -Settings $STSet @AdditionalOptions
  }

  # Sometimes $cim returns more than 1 object, looks like a PowerShell bug.
  # In those cases, get the last element of the list.
  return $cim
}


###
###  Shortcuts
###

function New-Shortcut {
  <#
  .SYNOPSIS
  Creates a shortcut (.lnk) file.
  ✓ Has Unicode support, which wasn't present natively.

  .PARAMETER Force
  Overwrites the destination if it already exists.

  .TODO
  - Implement `Force` for non-unicode shortcuts
  - Return the object that was created
  #>

  param(
    [Parameter(Mandatory = $true)][string]$LnkPath,
    [Parameter(Mandatory = $true)][string]$TargetExe,
    [string[]]$Arguments,
    [string]$WorkingDir,
    [string]$IconPath,
    [Parameter()][ValidateSet('Default', 'Minimized', 'Maximized')][string]$WindowStyle = 'Default',
    [switch]$Force
  )

  if ((Test-Path -LiteralPath $LnkPath) -and !$Force) {
    Write-DebugLog 'Link already exists, exiting.'
    Return # "AlreadyExists"
  }

  if ($Force) {
    $ForceParam = @{Force = $null }
  }
  else {
    $ForceParam = @{ }
  }

  $bitWindowStyle = @{
    Default   = 1;
    Maximized = 3;
    Minimized = 7
  }

  $ParentPath = Split-Path $LnkPath -Parent
  if (!(Test-Path $ParentPath)) {
    New-Item -Path $ParentPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
  }

  $nonASCII = '[^\x00-\x7F]'
  $HasUnicode = $LnkPath -cmatch $nonASCII

  if ($HasUnicode) {
    $RealLnkPath = $LnkPath
    $LnkPath = "$env:TEMP\$(New-Guid).lnk"
    Write-DebugLog "$RealLnkPath has Unicode characters. Temp file is: $LnkPath" -LogLevel Verbose
  }

  if ($Arguments) {
    Write-DebugLog "Arguments supplied: $Arguments" -LogLevel Verbose
  }
  $WshShell = New-Object -ComObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut($LnkPath)
  $Shortcut.TargetPath = $TargetExe
  $Shortcut.Arguments = $Arguments -join ' '

  if ($IconPath) {
    $Shortcut.IconLocation = $IconPath
  }
  
  $Shortcut.WorkingDirectory = $WorkingDir
  $Shortcut.WindowStyle = $bitWindowStyle[$WindowStyle]
  $Shortcut.Save()

  if ($HasUnicode) {
    Move-Item -Path $LnkPath -Destination $RealLnkPath @ForceParam
    Write-DebugLog "Moved $LnkPath to $RealLnkPath" -LogLevel Verbose
  }

  $result = Get-Item $RealLnkPath
  return $result
}

###
###  Win32 Shell Class
###

function Set-ShellStaticVerb {
  <#

  .VERSION 2023.04.28

  .SYNOPSIS
  Set an action for a static verb for a Win32 Shell Class, such as `open`, `edit`, `print`.

  .TODO
  Currently KHCU only, add HKLM support
  #>

  param(
    [Parameter(Mandatory = $true)][string]$Class,
    [Parameter(Mandatory = $true)][string]$Verb,
    [Parameter(Mandatory = $true)][string]$Target,
    [string]$Label
  )

  $result = @()

  $key = "HKCU:\SOFTWARE\Classes\${Class}\shell\${Verb}\(Default)"
  $result += Set-RegValue -FullPath $key -Value $Label -Type String -Force

  $key = "HKCU:\SOFTWARE\Classes\${Class}\shell\${Verb}\command\(Default)"
  $result += Set-RegValue -FullPath $key -Value $Target -Type String -Force

  $result = $result | Where-Object { $_ -ne $null }
  return $result
}

function Invoke-SHChangeNotify {
  <#
  .SYNOPSIS
  Function to call SHChangeNotify, which is used to notify the shell of changes.

  .DESCRIPTION
  Useful, for example, to refresh the icons after a file assoc change, so we don't have to restart Explorer.
  https://stackoverflow.com/questions/9986869/force-the-icons-on-the-desktop-to-refresh-after-deleting-items-or-stop-an-item

  .EXAMPLE
  Invoke-SHChangeNotify

  #>

  $code = @'
  [System.Runtime.InteropServices.DllImport("Shell32.dll")] 
  private static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);

  public static void Refresh()  {
      SHChangeNotify(0x8000000, 0x1000, IntPtr.Zero, IntPtr.Zero);    
  }
'@

  Add-Type -MemberDefinition $code -Namespace WinAPI -Name Explorer 
  [WinAPI.Explorer]::Refresh()
}


###
###  ASSOC
###

function New-FileAssoc {
  <#
  .VERSION 2023.04.29

  .SYNOPSIS
  Creates a new (basic) file association.

  .DESCRIPTION
  ✓ Creates a basic file asssociation. (see also `New-FileAssocExt`)
  ✓ Application is added to the "Open With" list as well.
  ! Association is created for the current user only (HKCU).

  .PARAMETER Extension
  The file extension to associate, for example 'jpg'

  .PARAMETER ExePath
  The path to the executable to use for the association.

  .PARAMETER Params
  The parameters to pass to the executable.
  The default is "%1", which means the target file.

  .PARAMETER IconPath
  The path to the icon to use for the association, including the icon index.
  For example: "C:\Windows\System32\imageres.dll,2"

  #>
  param(
    [Parameter(Mandatory = $true)][string]$Extension,
    [Parameter(Mandatory = $true)][string]$ExePath,
    [Parameter(Mandatory = $false)][string]$Params,
    [Parameter(Mandatory = $false)][string]$IconPath,
    [Parameter(Mandatory = $false)][string]$FriendlyAppName
  )

  $Extension = $Extension.ToLower() -replace '^\.', '' # Remove trailing dot if supplied by accident

  $ExeName = Split-Path $ExePath -Leaf
  if ([string]::IsNullOrEmpty($Params)) { $Params = "`"%1`"" }
  $OpenCmd = "$ExePath $Params"

  $result = @()

  $AppRegKey = "HKCU:\SOFTWARE\Classes\Applications\${ExeName}\shell\open\command\(Default)"
  $result += Set-RegValue -FullPath $AppRegKey -Value $OpenCmd -Type REG_EXPAND_SZ -Force

  $OpenWithRegKey = "HKCU:\SOFTWARE\Classes\.${Extension}\OpenWithList\${ExeName}\(Default)"
  $result += Set-RegValue -FullPath $OpenWithRegKey -Value $null -Type REG_SZ -Force

  if ($IconPath) {
    $IconRegKey = "HKCU:\SOFTWARE\Classes\Applications\${ExeName}\DefaultIcon\(Default)"
    $result += Set-RegValue -FullPath $IconRegKey -Value $IconPath -Type REG_EXPAND_SZ -Force
  }

  if ($FriendlyAppName) {
    $AppRegPath = "HKCU:\SOFTWARE\Classes\Applications\${ExeName}\FriendlyAppName"
    $result += Set-RegValue -FullPath $AppRegPath -Value $FriendlyAppName -Type REG_SZ -Force
  }

  $result = $result | Where-Object { $_ -ne $null }
  return $result
}

function New-FileAssocExt {
  <#
  .VERSION 2023.04.22

  .SYNOPSIS
  New File Assoc *EXTENDED* function; meaning an app registration is also created, eg. 7-Zip.zip
  Useful when multiple file types are associated with the same app; but they get different icons assigned.

  .PARAMETER Extension
  File extension for which to register the app association. Do not include the dot. Eg: 'zip', 'jpeg'

  .PARAMETER ExePath
  Path to the executable that would open this file type

  .PARAMETER Params
  The parameters to pass to the executable.
  The default is "%1", which means the target file.

  .PARAMETER IconPath
  Path to the icon that should be used for this file type, including the icon index.
  For example: "C:\Windows\System32\imageres.dll,2"

  .PARAMETER Description
  Description of the file type. This will be displayed in the "Open with" dialog.

  .PARAMETER AppRegSuffix
  Suffix to append to the app registration name. Eg: tmp -> 7-Zip_tmp.zip.
  Usually this is not needed, unless the app has already created its own registrations.

  .PARAMETER Force
  Force will remove the existing default association from this file type.

  .TODO
  - Add support for HKLM
  #>

  # Note to self: Past user choices are stored here:
  # HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts

  param(
    [Parameter(Mandatory = $true)][string]$Extension,
    [Parameter(Mandatory = $true)][string]$ExePath,
    [Parameter(Mandatory = $false)][string]$Params,
    [Parameter(Mandatory = $false)][string]$IconPath,
    [Parameter(Mandatory = $false)][string]$Description,
    [Parameter(Mandatory = $false)][string]$AppRegSuffix,
    [Parameter(Mandatory = $false)][string]$Verb,
    [Parameter(Mandatory = $false)][string]$VerbLabel,
    [Parameter(Mandatory = $false)][string]$FriendlyAppName,
    [Parameter(Mandatory = $false)][switch]$Force
  )

  if ([string]::IsNullOrEmpty($Verb)) { $Verb = 'open' }

  $Extension = $Extension.ToLower() -replace '^\.', '' # Remove traling dot if supplied by accident
  $AppName = (Get-Item $ExePath).BaseName
  if ($AppRegSuffix) { $AppRegSuffix = "_${AppRegSuffix}" }
  $AppRegName = "${AppName}${AppRegSuffix}.${Extension}"
  if ([string]::IsNullOrEmpty($Params)) { $Params = "`"%1`"" }
  $OpenCmd = "$ExePath $Params"

  $result = @()

  $AppRegPath = "HKCU:\SOFTWARE\Classes\${AppRegName}\shell\${Verb}\command\(Default)"
  $result += Set-RegValue -FullPath $AppRegPath -Value $OpenCmd -Type REG_SZ -Force

  if ($IconPath) {
    $IconRegKey = "HKCU:\SOFTWARE\Classes\${AppRegName}\DefaultIcon\(Default)"
    $result += Set-RegValue -FullPath $IconRegKey -Value $IconPath -Type REG_SZ -Force
  }

  if ($VerbLabel) {
    $LabelRegKey = "HKCU:\SOFTWARE\Classes\${AppRegName}\shell\${Verb}\(Default)"
    $result += Set-RegValue -FullPath $LabelRegKey -Value $VerbLabel -Type REG_SZ -Force
  }

  if ($Description) {
    $DescriptionPath = "HKCU:\SOFTWARE\Classes\${AppRegName}\(Default)"
    $result += Set-RegValue -FullPath $DescriptionPath -Value $Description -Type REG_SZ -Force
  }

  if ($FriendlyAppName) {
    $AppRegPath = "HKCU:\SOFTWARE\Classes\Applications\$((Get-Item $ExePath).Name)\FriendlyAppName"
    $result += Set-RegValue -FullPath $AppRegPath -Value $FriendlyAppName -Type REG_SZ -Force
  }

  $ExtRegPath = "HKCU:\SOFTWARE\Classes\.${Extension}\(Default)"
  $check = Get-RegValue -FullPath $ExtRegPath -ErrorAction SilentlyContinue
  if ((!$check) -or (($Check -ne $AppRegName) -and $Force)) {
    $result += Set-RegValue -FullPath $ExtRegPath -Value $AppRegName -Type REG_SZ -Force
  }

  if ($Force) {
    $UserChoicePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.${Extension}\UserChoice"
    if (Test-Path -LiteralPath $UserChoicePath) {
      Write-DebugLog "Removing existing user choice for file extension .${Extension}: ${UserChoicePath}"
      $TempFile = "$env:TEMP\RemoveUserChoice_${Extension}.reg"
      Write-DebugLog "Temp reg file: $TempFile" -LogLevel Verbose

      $UserChoiceDelReg = @"
Windows Registry Editor Version 5.00
[-HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.${Extension}\UserChoice]
"@
      Set-Content $TempFile $UserChoiceDelReg -Force
      # This will elevate to admin at each schedule, not great.
      regedit / s $TempFile | Out-Null
      if ($DebugPreference -ne 'Continue') {
        Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
      }
      
    }
  }

  $result = $result | Where-Object { $_ -ne $null }
  return $result
}

###
###  PATHs
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
      [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
  }
	
  if ( @('User', 'All') -icontains $Scope) {
    $Paths += `
      [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User).Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
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
    Where-Object SideIndicator -EQ '=>' | `
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
    [Environment]::SetEnvironmentVariable('Path', "$newEnvTargetUser", [System.EnvironmentVariableTarget]::User)
  }

  return $newEnvTargetUser
}

function Remove-UserPaths {
  <#
  .SYNOPSIS
  Removes paths from the USER scope PATH environment variable.

  .PARAMETER Paths
  ✓ Removes a list of paths from the user's PATH environment variable.
  ✓ The remaining paths are unchanged
  ✓ Missing paths are automatically ignored

  .EXAMPLE
  Remove-UserPaths -Paths @('C:\Program Files\Git\cmd', 'C:\Program Files\Git\usr\bin')

  .TODO
  - Add support for Machine scope
  #>

  param(
    [string[]]$Paths
  )

  [String[]]$existingPathsUser = Get-EnvPathsArr('User')

  $remainingPaths = Compare-Object -ReferenceObject $existingPathsUser -DifferenceObject $Paths | `
    Where-Object SideIndicator -EQ '<=' | `
    Select-Object -ExpandProperty InputObject

  $removePaths = Compare-Object -ReferenceObject $existingPathsUser -DifferenceObject $installPaths -ExcludeDifferent -IncludeEqual | `
    Select-Object -ExpandProperty InputObject

  if ($removePaths.Count -gt 0) {
    $newUserEnvString = $newPaths -join ';'    

    Write-DebugLog "Removing the following paths from user %PATH%:`n- $($removePaths -join "`n- ")`n"
    Write-Verbose "[Remove-UserPaths]: Updating user %PATH% to:`n- $($remainingPaths -join "`n- ")`n"

    [Environment]::SetEnvironmentVariable('Path', "$newUserEnvString", [System.EnvironmentVariableTarget]::User)
  }
  else {
    Write-DebugLog 'No paths to remove from user %PATH%.'
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
    Write-DebugLog '%PATH% in shell already up to date.'
    return
  }

  Write-Verbose "Updates to %PATH% detected:`n`n $($diff | Out-String) `n"
  Write-DebugLog 'Refreshing %PATH% in current shell..'
  $env:Path = $pathsInRegistry -join ';'
}

###
###  Folders
###

function Get-ExeVersion {
  <#
  .SYNOPSIS
  Gets the version of an executable file.

  .EXAMPLE
  Get-ExeVersion -Path 'C:\Program Files\Git\cmd\git.exe'
  #>

  param(
    [string]$Path
  )

  $version = (Get-Item $Path).VersionInfo.FileVersionRaw.ToString()
  return $version
}

function Set-FolderComment {
  <#
  .SYNOPSIS
  Sets a comment on a folder that's visible in Windows Explorer.
  NOTE: This function is not fully working, need to do some debugging.

  .Example
  Set-FolderComment -Path 'C:\Program Files\Git' -Comment 'Git for Windows'
  #>

  param(
    [string]$Path,
    [string]$Comment
  )

  if (!(Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path
  }

  $IniPath = "$Path\desktop.ini"
  
  $result = $false

  if (Get-Content -Path $IniPath -ErrorAction SilentlyContinue | Select-String -SimpleMatch "InfoTip=$Comment") {
    Write-DebugLog "Folder comment at $Path already set to ``$Comment``."
  }
  elseif (!(Test-Path $IniPath)) {
    # Create the file from scratch if it doesn't exist
    $Content = @"
[.ShellClassInfo]
InfoTip=$Comment
"@
    Set-Content -Path $IniPath -Value $Content
    $result = $true
  }
  else {
    # Update the File
    $Content = (Get-Content $IniPath ) -as [Collections.ArrayList]
    Write-DebugLog "Contents of ${IniPath}:"
    Write-Verbose [String[]]$Content

    $HeaderLineNumber = $Content | Select-String -Pattern '^\[\.ShellClassInfo\]' | Select-Object -First 1 -ExpandProperty LineNumber
    If (!$HeaderLineNumber) {
      $Content.Insert($Content.Count, '[.ShellClassInfo]')
      $HeaderLineNumber = $Content.Count
    }

    $CommentLineNumber = $Content | Select-String -Pattern '^InfoTip=' | Select-Object -First 1 -ExpandProperty LineNumber
    If (!$CommentLineNumber) {
      $Content.Insert($Content.Count, "InfoTip=$Comment")
    }
    else {
      $Content[$CommentLineNumber - 1] = "InfoTip=$Comment"
    }

    $Content | Set-Content -Path $IniPath -Force
    $result = $true
  }

  # Check Attributes
  $IniFile = Get-Item $IniPath -Force
  $IniAttr = $IniFile.Attributes
  if ($IniAttr -notlike '*Hidden*' -or $IniAttr -notlike '*System*') {
    Set-ItemProperty -Path $IniFile -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
    $result = $true
  }

  $FolderAttr = (Get-Item $Path).Attributes -split ', '
  if ('ReadOnly' -notin $FolderAttr) {
    Set-ItemProperty -Path $Path -Name Attributes -Value ([System.IO.FileAttributes]::ReadOnly)
    $result = $true
  }

  return $result
}

function Invoke-FilePicker {
  <#
  .VERSION 2023.04.22
  
  #>
  param(
    [string]$Path,
    [string]$Filter = 'All files (*.*)|*.*',
    [bool]$Multiselect = $false
  )

  # Load the assembly
  Add-Type -AssemblyName System.Windows.Forms

  if (!$Path) {
    $Path = Get-Location
  }
  else {
    $Path = Resolve-Path $Path
  }

  # Create a new OpenFileDialog object
  $fileDialog = New-Object System.Windows.Forms.OpenFileDialog

  # Set the dialog properties
  $fileDialog.Title = 'Select a file'
  $fileDialog.InitialDirectory = $Path
  $fileDialog.Multiselect = $Multiselect
  $fileDialog.Filter = $Filter

  # Show the dialog and get the result
  if ($fileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    return
  }

  $selectedFile = $fileDialog.FileNames
  return $selectedFile
}

###
### Font
###

function Install-Font {
  <#
  .VERSION 2023.04.22

  .SYNOPSIS
  Installs a font file (.ttf, .otf, etc).
  Don't remember exactly if it's in the user or machine scope.

  .EXAMPLE
  Install-Font -SourcePath 'C:\Windows\Fonts\Consolas.ttf'
  #>

  param(
    [string]$SourcePath
  )

  $UserFontPath = "$($env:SystemDrive)\Users\$env:UserName\AppData\Local\Microsoft\Windows\Fonts\"
  $FontName = Split-Path $SourcePath -Leaf
  if (Test-Path "$UserFontPath\$FontName") {
    Write-DebugLog 'Font already installed.' -LogLevel Debug
    return
  }

  Write-Debug "Installing font from $SourcePath"
  $result = (New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere($SourcePath, 0x14)
  return $result
}

###
###  Dropbox
###

Function Get-DropboxInstallPath {
  <#
  .VERSION 20230406

  .SYNOPSIS
  Get the Dropbox's "data" folder path for the current user

  .EXAMPLE
  Write-Host "The Dropbox sync folder is: $(Get-DropboxInstallPath)"
  #>
  $Path = "$env:LOCALAPPDATA\\Dropbox\\info.json"

  if (!(Test-Path $Path)) {
    Throw "$Path not found. Dropbox not installed?"
  }

  $Data = Get-Content $Path | ConvertFrom-Json
  Return $Data.personal.path
}

function Get-StreamContent {
  <#
  .VERSION 20230410

  .SYNOPSIS
  Get the content of an NTFS file or directory stream

  .EXAMPLE
  Get-StreamContent -Path 'C:\users\admin\Dropbox\Temp\hello.txt' -StreamName 'com.dropbox.ignored'

  .EXAMPLE
  Get-StreamContent -Path 'C:\users\admin\Dropbox\Temp' -StreamName 'com.dropbox.ignored'
  #>
  
  param (
    [string]$Path,
    [Parameter(Mandatory)][string]$StreamName,
    [Parameter()][ValidateSet('Default', 'Byte')][string]$Encoding = 'Default'
  )
  $Path = Resolve-Path $Path
  $result = cmd / c dir $Path / r | Select-String -SimpleMatch ":$StreamName"
  if ($null -ne $result) {
    $Path = Resolve-Path $Path
    $streamPath = $Path + ":$StreamName"
    $content = Get-Content -Path $streamPath -Encoding $Encoding
    return $content
  }
  return $null
}

Function Set-DropboxIgnoredPath {
  <#
  .VERSION 20230415

  .SYNOPSIS
  Sets a path to be ignored by Dropbox

  .EXAMPLE
  Set-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp'
  Set-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp' -Unignore
  Set-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp\hello.txt'
  Set-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp\hello.txt' -Unignore
  #>

  [CmdletBinding()]
  param(
    [string]$Path,
    [switch]$Unignore
  )

  $ErrorAction = $PSBoundParameters['ErrorAction']
  if ([string]::IsNullOrEmpty($ErrorAction)) {
    Write-Verbose "Setting default value for ErrorAction: 'Stop'"
    $ErrorAction = 'Stop'
  }

  if (!(Test-Path $Path)) {
    switch ($ErrorAction) {
      'SilentlyContinue' { return }
      'Continue' { Write-Error "1Error: Path $Path not found." }
      'Stop' { Throw "Error: Path $Path not found." }
    }
  }

  $result = $false # Nothing has been done yet
  
  if (!$Unignore) {
    $check = Get-Content -Path $Path -Stream com.dropbox.ignored -ErrorAction SilentlyContinue
    if ($check -ne 1) {
      Set-Content -Path $Path -Stream com.dropbox.ignored -Value 1 -ErrorAction Stop
      $result = $true
    }
  }
  else {
    try {
      $check = $true
      $check = Get-Content -Path $Path -Stream com.dropbox.ignored -ErrorAction Stop
    }
    catch {
      $check = $false
    }

    if ($check) {
      Clear-Content -Path $Path -Stream com.dropbox.ignored -ErrorAction Stop
      $result = $true
    }
  }

  return $result
}

Function Get-DropboxIgnoredPath {
  <#
  .VERSION 20230410

  .SYNOPSIS
  Checks if a path is ignored by Dropbox

  .EXAMPLE
  Get-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp'
  Get-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp' -Unignore
  Get-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp\hello.txt'
  Get-DropboxIgnoredPath -Path 'C:\users\admin\Dropbox\Temp\hello.txt' -Unignore
  #>

  param(
    [string]$Path
  )

  $Stream = Get-StreamContent -Path $Path -Stream com.dropbox.ignored
  return !!$stream
}

Function Set-DropboxItemOfflineMode {
  <#
  .VERSION 20230415

  .SYNOPSIS
  Sets a path to be ignored by Dropbox

  .EXAMPLE
  Set-DropboxItemOfflineMode -Path 'C:\users\admin\Dropbox\Temp' -Mode 'Offline'
  Set-DropboxItemOfflineMode -Path 'C:\users\admin\Dropbox\Temp2\hello.json' -Mode 'OnlineOnly'
  #>

  [CmdletBinding()]
  param(
    [string]$Path,
    # Mode can be OnlineOnly or Offline
    [Parameter(Mandatory)][ValidateSet('OnlineOnly', 'Offline')][string]$Mode  
  )

  $ErrorAction = $PSBoundParameters['ErrorAction']
  if ([string]::IsNullOrEmpty($ErrorAction)) {
    Write-Verbose "Setting default value for ErrorAction: 'Stop'"
    $ErrorAction = 'Stop'
  }

  if (!(Test-Path $Path)) {
    switch ($ErrorAction) {
      'SilentlyContinue' { return }
      'Continue' { Write-Error "1Error: Path $Path not found." }
      'Stop' { Throw "Error: Path $Path not found." }
    }
  }

  if (!(Get-Process 'dropbox' -ErrorAction SilentlyContinue)) {
    switch ($ErrorAction) {
      'SilentlyContinue' { return }
      'Continue' { Write-Error 'Error: Dropbox is not running.' }
      'Stop' { Throw 'Error: Dropbox is not running.' }
    }
  }
  
  $Path = Get-RealPath $Path

  $Modes = @{
    'OnlineOnly' = 0
    'Offline'    = 1
  }

  $VerbTexts = @('Make online-only', 'Make available offline')

  $shell = New-Object -ComObject Shell.Application

  if (Get-Item -Path $Path | Select-Object -ExpandProperty PSIsContainer) {
    # Target is a folder
    $namespace = $shell.Namespace($Path)
    $item = $namespace.Self
  }
  else {
    # Target is a file
    $folderPath = Split-Path $filePath -Parent
    $namespace = $shell.Namespace($folderPath)
    $item = $namespace.ParseName($fileName)
  }
  
  $verbs = $item.Verbs()

  $actionVerb = $verbs | Where-Object { $_.Name -eq $VerbTexts[$Modes[$Mode]] }
  # Write-Debug "Looking for ActionVerb: $($VerbTexts[$Modes[$Mode]])"
  if ($null -eq $actionVerb) {
    if ($verbs | Where-Object { $_.Name -eq $VerbTexts[($Modes[$Mode] + 1) % 2] }) {
      # Write-Debug "$Path is already in $Mode mode."
      return $false
    }
    else {
      Write-Verbose "$($verbs | Out-String)"
      Throw "Error: Verb '$($VerbTexts[$Modes[$Mode]])' not found."
    }
  }

  try {
    $actionVerb.DoIt()
    return $true
  }
  catch {
    switch ($ErrorAction) {
      'SilentlyContinue' { return }
      'Continue' { Write-Error $_ }
      'Stop' { Throw $_ }
    }
  }
}
