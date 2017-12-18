@ECHO OFF
powershell -File .\InstallerScript.ps1 -Version 2.7.14 -Arch 32 -PostInstallScript post_install_script.pyw
