# Python Pre-Setup
> Prepare a Windows Computer to install a Python Application.

On Windows, Python is not installed by default. This Pre-Setup prepare any Windows 7 or newer for the Installation of your Python Application. It automatically downloads and installs Python with some modules, set paths and much more.

<!--![](header.png)-->

## Installation

Download the script files, customize them to fit your needs and provide them to your user.

There are three script files:

1. **Setup.cmd**:This is what your user will run. It only starts InstallSetup.ps1 with some arguments. In most cases, you just have to customize these arguments in this file to your needs, which is very self-explaining.

2. **InstallSetup.ps1**: You don't have to change anything in this file. This file is where the magic happens. It downloads and installs Python, set the %PATH% Environment Variable and so on.

3. **post_install_script.pyw**: This is a sample script. You may use your own one. It will run after the Python installation has finished.

## Usage example

A simple sample is provided with the three script files. Just copy them and provide them to your user.

The way it is configured by default, you won't see anything when running it. It hides every output and window, so you won't get any user feedback when Python has been installed. Actually, you have to check the installation manually or check whether or not the post_install_script has been run, if you want to verify if everything went right. You can change this behaviour, if you like.

To customize the experience, start with the *Setup.cmd*.

### Setup.cmd

Call the **InstallerScript.ps1** Script using these parameters:

* **-Version**: Python Version you want to install. Please make sure to include a full version number like '3.6.4' or '2.7.14'. Something like '2.7' propably won't work!

* **-Arch**: Specify if you want to install 32 bit or 64 bit Python. Just set it to '32' or '64'.

* **PostInstallScript**: Filename of a Pythonscript that will run if Python has been installed.

* **Hidden**: Hide any output or window from user. This is used to not distract your user, but it is less informative! To hide, set this to '"Hide"' (default), to disable hiding, set this to anything but '"Hide"'.

### Post Install Script

This script will be run after Python has been installed on the computer and obviously uses the installed Python interpreter to run. Customize or replace it as you like.

### InstallerScript

You propably don't want to change much in this file. However, some details are hidden in this code and not customizable yet, so for some special usages, you have to dig into this code - but I promise, it will be easy.

* **Add/Remove custom python modules**: Each Python installation will include some modules by default. These default modules can be customized by scrolling near the bottom of the file and editing the '$modules'-Array, which you can find easily.
* **Don't hide the output**: Usually, you should be able to disable hiding by providing a '-Hide' Paramter in your 'Setup.cmd'. If this doesn't work, you can go to the beginning of the InstallerScript just below the line '#requires -version 2.0'. In the following *param*-Block, set *[string]$Hidden* to ""

### More

These are some basic usage samples. You should be able to handle most task just following these instructions. For a more detailed desciption and more examples, please refer to the [Wiki][wiki].

## Release History

- 1.0.0
	- Compatible with Windows 7 or newer (Powershell 2.0)
	- Download and install Python from official sources
	- Easily customize Python Version
	- Easily customize Architecture (32bit vs 64bit Python)
	- Include customizable default modules
	- Optional hide installation process
	- Optional run custom python script after installation has finished

## Meta

Micha Grandel – [@michagrandel](https://twitter.com/michagrandel) – talk@michagrandel.com

Distributed under the MIT license. See [https://github.com/michagrandel/Python-Pre-Setup/blob/master/LICENSE](LICENSE) for more information.

[https://github.com/michagrandel/Python-Pre-Setup](github.com/michagrandel/)

## Contributing

1. Fork it (<https://github.com/michagrandel/Python-Pre-Setup/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request

<!-- Markdown link & img dfn's -->
[wiki]: https://github.com/michagrandel/Python-Pre-Setup/wiki
