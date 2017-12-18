<#
.SYNOPSIS
    Download and install python
.DESCRIPTION
    Download and install python version specified by -version PYTHON_VERSION and -arch 32_OR_64
.EXAMPLE
    PS C:\> InstallerScript.ps1 -version 2.7.14  
    Installs Python 2.7.14 (32-bit) into default installation path
.EXAMPLE
    PS C:\> InstallerScript.ps1 -version 3.6.3 -InstallTo D
    Installs Python 3.6.3 (32-bit) into installation path on drive D:
.EXAMPLE
    PS C:\> InstallerScript.ps1 -version 2.7.10 -arch 64  
    Installs Python 2.7.10 (64-bit) into default installation path
.NOTES
    Author: Micha Grandel
    Email:  talk@michagrandel.de
    Date:   December 18, 2017    
#>
#requires -version 2.0
param (
    # Python Version to install. Please provide a full version number like 2.7.14 or 3.6.3!
    [Parameter(Mandatory=$true)][string]$Version = "",  
    # 32 to install 32-bit Python, 64 to install 64-bit Python
    [int]$Arch=32,  
    # Specifies the drive (only the letter, without colon) on which python will be installed. Default "C"
    [string]$InstallTo="C", 
    # verbose level, value may range from 0 to 3, default: 0
    #[int]$Verbose=0,  
    # force yes on all questions, default: False
    [bool]$Force=$true,
    [string]$PostInstallScript="",
    [string]$Hidden="Hide"
)

$Hide = $Hidden -eq "Hide"

# check windows version
if ([Environment]::OSVersion.Version.Major -lt 10) {
    # cancel on windows versions older than 7
    # this is probably not necessary as older versions don't have a powershell, but who cares...
    if ([Environment]::OSVersion.Version.Major -lt 6) {
        Write-Error "This script requires Windows 7 or higher!"
        exit
    }
    # warning for windows 8.1
    if ([Environment]::OSVersion.Version.Minor -eq 3) {
        Write-Warning "This script has not been tested on Windows 8.1 or Windows Server 2012 R2."
        Write-Warning "It should work fine, but please report any bugs!"
    }
    # warning for windows 8
    if ([Environment]::OSVersion.Version.Minor -eq 2) {
        Write-Warning "This script has not been tested on Windows 8 or Windows Server 2012."
        Write-Warning "It should work fine, but please report any bugs!"
    }
}

# $ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$ScriptPath = $MyInvocation.MyCommand.path
$CurrentWorkingDirectory = split-path -parent $ScriptPath 
$ScriptName = $MyInvocation.MyCommand.name

if($Version -eq "" -OR -NOT ($Arch -eq 32 -OR $Arch -eq 64)) {
    Write-Host ("Usage: {0} [-Version] <String> [[-Arch] <Int32>] [[-InstallTo] <String>] [[-Force] <Boolean>] [<CommonParameters>]" -f $ScriptName)
    Write-Host ('Try "Get-Help .\{0}" to get more help ' -f $ScriptName)
    exit
}


# set some colors
#$Background = $Host.UI.RawUI.BackgroundColor
#$Foreground = $Host.UI.RawUI.ForegroundColor

# creates a shortcut <name> to <target>
function Create-ShortCut {
    param ( [string]$Target, [string]$Name )
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($Name)
    $Shortcut.TargetPath = $Target
    $Shortcut.Save()
}

Function Execute-Command ($commandTitle, $commandPath, $commandArguments)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $commandArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    [pscustomobject]@{
        commandTitle = $commandTitle
        stdout = $p.StandardOutput.ReadToEnd()
        ExitCode = $p.ExitCode  
    }
}

# install Python <PyVersion> <Architecture> bit on Drive <InstallDrive>
function Install-Python {
    param ([string]$PyVersion = "2.7.14", [int]$Architecture = 32, [string]$InstallDrive="C", [bool]$ForceYes=$false, [bool]$Verbose=$false, [bool]$Debug=$false, [string]$PostInstallScript="", [string]$Hidden="Hide")
    
    $Hide = $Hidden -eq "Hide"
    
    # cancel if architecture is not valid
    if (-NOT ($Architecture -eq 32 -OR $Architecture -eq 64)) {
        Write-Error "Error: Architecture has to be 32 (for 32-bit python) or 64 (for 64-bit python)!"
        return
    }
    
    # get admin to install software
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        if (-NOT $Hide) { Write-Warning "To install python, please run this script as admin!" }

        If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        {
            $AdminScript = $False
            # Relaunch as an elevated process:
            if (Test-Path -Path $ScriptPath -PathType leaf) {
                if (-NOT $Hide) { Write-Host "Restart as admin ... (Will propably open a new window)" }
                $args = ("-ExecutionPolicy Bypass",'-File',('"{0}"' -f $ScriptPath), ("-Version {0}" -f $PyVersion), ("-Arch {0}" -f $Architecture), ("-InstallTo {0}" -f $InstallDrive), ('-PostInstallScript "{0}"' -f $PostInstallScript))
                if ($Hide) { $args += '-Hidden "Hide"' }
                if ($Verbose) { $args += "-vb" }
                if ($Debug) { $args += "-db"}
                if ($Hide) {
                    $AdminScript = Start-Process powershell.exe -ArgumentList $args -Verb RunAs -WindowStyle Hidden
                } else {
                    $AdminScript = Start-Process powershell.exe -ArgumentList $args -Verb RunAs
                }
            }
            if ($AdminScript) {
                $AdminScript.WaitForExit()
            } else {
                if (-NOT $Hide) { Write-Host "Goodbye. (Resume in new window)" }
            }
            exit
        }
    }

    Write-Host ("Installing Python {0} ({1} bit):" -f $PyVersion, $Architecture)
    Write-Host ""
    # set download folder from registry key
    $registry_key = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $guid_download = "{374DE290-123F-4565-9164-39C4925E467B}"
    $download_folder = (Get-ItemProperty -Path $registry_key -Name "$guid_download")."$guid_download"
    
    $VersionNumber = $PyVersion.Split(".")[0,1] -join ""    
    $PythonDirectory = "{0}:\Developer\Python" -f $InstallDrive
    
    if ($Architecture -eq 32) {
        $Url = "https://www.python.org/ftp/python/{0}/python-{0}.msi" -f $PyVersion
        $DownloadTarget = "{0}\python-{1}.msi" -f $download_folder, $PyVersion
        $InstallDirectory = "{0}:\Developer\Python{1}" -f $InstallDrive, $VersionNumber
    } else {
        $Url = "https://www.python.org/ftp/python/{0}/python-{0}.amd64.msi" -f $PyVersion
        $DownloadTarget = "{0}\python-{1}.amd64.msi" -f $download_folder, $PyVersion
        $InstallDirectory = "{0}:\Developer\Python{1}x{2}" -f $InstallDrive, $VersionNumber, $Architecture
    }
    
    # create installation directory
    if( -NOT (Test-Path -Path $InstallDirectory) ) { New-Item -ItemType directory -Path $InstallDirectory }
    Write-Host ("Downloading Python ...")
    Write-Verbose ("from {0}" -f $Url)
    Write-Verbose ("Saving to {0}" -f $DownloadTarget)
    
    # download python setup package
    (New-Object Net.WebClient).DownloadFile($Url, $DownloadTarget)
    Write-Verbose("Installing to {0}" -f $InstallDirectory)

    #Start-Process msiexec.exe /i $DownloadTarget -Verb RunAs
    $MsiSetup = Start-Process -FilePath "msiexec" -ArgumentList @("/i", $DownloadTarget, "/Q", ("TARGETDIR={0}" -f $InstallDirectory)) -WorkingDirectory $download_folder -Verb runAs -PassThru
    $MsiSetup.WaitForExit()
    
    if ($Architecture -eq 32) { 
        $ShortCutName = ("python{0}" -f $VersionNumber)
        $ShortCutFile = ("{0}\python{1}.lnk" -f $PythonDirectory, $VersionNumber) 
        $ShortCutPipFile = ("{0}\pip{1}.lnk" -f $PythonDirectory, $VersionNumber)
    } else { 
        $ShortCutName = ("python{0}_64" -f $VersionNumber)
        $ShortCutFile = ("{0}\python{1}_64.lnk" -f $PythonDirectory, $VersionNumber)
        $ShortCutPipFile = ("{0}\pip{1}_64.lnk" -f $PythonDirectory, $VersionNumber)
    }
    
    # create shortcuts
    Create-ShortCut -Target ("{0}\python.exe" -f $InstallDirectory) -Name $ShortCutFile
    Create-ShortCut -Target ("{0}\Scripts\pip.exe" -f $InstallDirectory) -Name $ShortCutPipFile
    
    # set PATH
    if (-NOT (Get-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment’ -Name PATH).path.StartsWith($PythonDirectory)) {
        $OldPath = (Get-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment’ -Name PATH).path
        $NewPath = “{0};{1}” -f $PythonDirectory, $OldPath
        Write-Verbose ('Set path to "{0};{1}"' -f $PythonDirectory, $NewPath)
        Set-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment’ -Name PATH -Value $NewPath
    }
        
    if ($Force -OR $Hide) {
        $ApplyChanges = 'y'
    } else {
        Write-Host "Do you want to restart the Windows Explorer to apply all changes without reboot?"
        $ApplyChanges = Read-Host -prompt '[Y] Yes [N] No (default is "Y")'
    }
    if (-NOT ($ApplyChanges.StartsWith("n", "CurrentCultureIgnoreCase"))) {
        Write-Host ('Restarting Windows Explorer ...')
        Stop-Process -ProcessName explorer
    }
    [pscustomobject]@{
        Version = $PyVersion
        Architecture = $Architecture
        Directory = $InstallDirectory
    }

}

function Install-Modules {
    param ([string]$PyVersion = "2.7.14", [int]$Architecture = 32, [string]$Path='.', [array]$modules=(''))
    Write-Host ("Installing {0} modules:" -f $modules.Length)
    
    
    if ($Architecture -eq 32) {
        $DownloadTarget = "{0}\python" -f $download_folder, $PyVersion
        $InstallDirectory = "{0}:\Developer\Python{1}" -f $InstallDrive, $VersionNumber
    } else {
        $DownloadTarget = "{0}\python-{1}.amd64.msi" -f $download_folder, $PyVersion
        $InstallDirectory = "{0}:\Developer\Python{1}x{2}" -f $InstallDrive, $VersionNumber, $Architecture
    }
    $Python = ("{0}\python.exe" -f $Path)
    $Pip = ("{0}\Scripts\pip.exe" -f $Path)
    
    [int]$ModuleCount = $modules.Length
    [int]$CurrentModule = 0
    
    ForEach ($module in $modules) {
        $CurrentModule += 1
        $PipInstall = Start-Process -FilePath $Pip -ArgumentList ("install", $module, "-qqq") -PassThru -Wait -NoNewWindow
        #Write-Process("{0}" -f $CurrentModule, $ModuleCount, $module) 
        Write-Progress -Activity ("Installing {0} modules. Please wait, this will take some time!" -f $ModuleCount) -Status ("Please Wait... {0} of {1} completed ({2}%), recently installed: {3}" -f $CurrentModule, $ModuleCount, ($CurrentModule / $ModuleCount * 100), $module) -PercentComplete ($CurrentModule / $ModuleCount * 100)
    }
    #$PipInstall = Start-Process -FilePath $Pip -ArgumentList ("freeze") -PassThru -redirectoutput Write-Host -NoNewWindow
    $PipFreeze = Execute-Command -commandTitle "Disable Monitor Timeout" -commandPath "$Pip" -commandArguments " freeze"
    Write-Host ("{0} modules installed." -f $ModuleCount)
}

$python = Install-Python $Version -Architecture $Arch -InstallDrive $InstallTo[0] -Verbose ($VerbosePreference -eq "Continue") -ForceYes $Force -Debug ($DebugPreference -eq "Inquire") -PostInstallScript "$PostInstallScript" -Hide $Hidden

Write-Host("Python {0} ({1}-bit) installed successfully in {2}" -f $Python.Version, $Python.Architecture, $Python.Directory)

$modules = (
    "appdirs",      # paths for applications configuration, logging and more
    "Babel",        # more support for localisation and internationalization
    "behave",       # Behaviour Driven Development
    "cmd2",         # Interactive Command Line Interfaces
    "colorama",     # Colored Terminal
    "cryptography", # Cryptography
    "numpy",        # Vector Math
    "Pillow",       # Imaging (replace for Python Image Library) 
    "psutil",       # utilities for processes
    "pycountry",    # Information for Countries and Languages
    "PyOpenGL",     # OpenGL
    "PyOpenGL-accelerate", # accelerated OpenGL 
    "PySide",       # Qt: Graphical User Interface
    "pytz",         # Timezone information
    "PyYAML",       # Support for YAML files
    "Qt.py",        # Qt version independent
    "RandomWords",  # get random words, e.g. to make strong passwords
    "six",          # compatibility for Python2 and Python3
    "tuf",          # The Update Framework
    "Yapsy",         # Simple Plugin Framework
    "pywin32"       # for Windows specific methods
)

$InstalledModules = Install-Modules -PyVersion $Python.Version -Architecture $Python.Architecture -Path $Python.Directory -Modules $modules
Write-Host ("Post-Install Scripts: {0}\{1}" -f $CurrentWorkingDirectory, $PostInstallScript)

if (-NOT ($PostInstallScript -eq "") -AND (Test-Path -Path ("{0}\{1}" -f $CurrentWorkingDirectory, $PostInstallScript) -PathType leaf)) {
    Write-Host "Start Post-Install Scripts ..."
    Write-Host ('Run scripts in "{0}"' -f $CurrentWorkingDirectory)
    $PostInstallScriptResult = Start-Process -FilePath ("{0}\pythonw.exe" -f $Python.Directory) -ArgumentList ("{0}\{1}" -f $CurrentWorkingDirectory, $PostInstallScript) -WorkingDirectory "$CurrentWorkingDirectory" -Verb runAs -Wait
    # $PostInstallScriptResult = Execute-Command -commandTitle "Post Install Script" -commandPath ("{0}\python.exe" -f $Python.Directory) -commandArguments (" {0}" -f $PostInstallScript)
    # Write-Host ("{0}" -f $PostInstallScriptResult.stdout)
} else {
    Write-Host "No Post-Install Script."
}
Write-Host "Finished successfully. Enjoy! :)" -foregroundcolor "DarkGreen"

$formAssembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

if (-NOT $Hide) {
    $oReturn = [System.Windows.Forms.Messagebox]::Show(("Python {0} ({1}-bit) has been installed." -f $Python.Version, $Python.Architecture))
}