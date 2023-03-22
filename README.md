# Useful/Control-WinApps

A very neat script that I found on [github.com/sergueik/powershell_selenium](https://github.com/sergueik/powershell_selenium/blob/master/powershell/button_selenium.ps1).

It implements the following Windows classes: `WinAPI`, `Win32WindowEvents`, and some UI elements, such as `Win32Window`, `Win32CheckBox`, `Win32Label`, `Win32ListBox`, `Win32TextBox`, `Win32Button`.

`WinAPI` and `Win32WindowEvents` are particularly useful, because they enable interation with other Windows applications, directly from PowerShell, using the Windows API.

Usage:

```powershell
./Control-WinApps.ps1
$window = [System.Windows.Win32Window]::FromProcessName("explorer")
$window.Hwnd
```

# Useful/PS-WinHelpers

A collection of useful PowerShell functions and classes that I use in my scripts, such as:
* Wrappers around built-in PowerShell functions, for making them more efficient. (eg. the registry functions)
* Others are re-implementaitons of PowerShell DSC functionality (eg. `Install-Font`, `New-Shortcut`, etc.). Desired State Configuration is, regrettably, suprisingly unsuable on desktops, because it requires admin to run and needs the user's credentials.
* Other useful functions like logger, checking for admin rights, etc.

Categories:
* PowerShell Scripting
* Registry manipulation
* Scheduled Tasks
* Shortcuts
* Win32 Shell Class
* File Associations
* %PATH%
* Folders
* Font
* Dropbox
  
# Useful/Scripts
Useful scripts that I always like to have around, preferably in `$PATH`.

## ccd.ps1

A replacement for the `cd` command in certain cases.

It opens a Windows Forms folder picker, and changes the current directory to whatever you select.

Handy when you're in a deep directory structure, so you don't have to do many `dir`s and `cd`s.

After chaning the location, you can go back to the previous path with `popd` (The script uses `Push-Location` in the background.)

```
ccd
...
popd
```

![ccd.ps1](res/ccd.png)


## code..cmd / code..sh

Launches VS Code in the current folder when you mistyped `code.` instead of `code .`

### Usage:

```powershell
code.
```

## ConEmu.cmd

Opens a ConEmu shell in the current folder, or the specified directory.
Similar to `code .`

### Usage:

```
ConEmu

- or -

ConEmu .

- or -

ConEmu /src/MyProject
```

## gRefreshToken.ps1

Generates a fresh auth token and drops it in the root of the git repo as `token.secret`
It's a convention that I use in my projects.

### Usage:

```powershell
gRefreshToken
```

## k.cmd

Kubectl alias for Windows.

### Usage:

```powershell
k get pods
```

## ll.cmd

`ls -l` alias for Windows.

### Usage:

```powershell
ll

- or -

ll /
```

## mk.cmd

`minikube` + `minikube kubectl` alias for Windows.
Checks if the first parameter is specific to minikube, then runs `minikube %*`.
Otherwise it assumes it's a kubectl command, and runs `minikube kubectl -- %*`.

set DIRECT_COMMANDS=:

### Usage:

```powershell
mk start
mk get pods
```

## Refresh-Path.ps1

Refresh `$env:PATH` in the current shell to whatever is set in Registry.
Useful when new apps were installed and you don't want to close your existing shells.

### Usage:

```powershell
Refresh-Path
```

## Toggle-TarkMode.ps1

Toggles Windows 10's Dark Mode.

### Usage:

```powershell
Toggle-TarkMode
```

## watch.cmd

`watch` alias for Windows.
Set `%DELAY%` for a custom delay, default is 3 seconds.

### Usage:

```powershell
set DELAY=5
watch dir c:\
```



# Useful/Regs

Useful registry files that I like to have around.
