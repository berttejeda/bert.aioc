# Overview

This is my custom configuration of the [ConsoleZ](https://github.com/cbucher/console) terminal emulator 
that I use when working from Windows machines.

This configuration does work from POSIX-Compliant machines, but I haven't
thouroughly tested this on anything other than Windows 10.

# Components

This project makes use of the following:
- [Powershell](https://learn.microsoft.com/en-us/powershell/)
- [ConsoleZ](https://github.com/cbucher/console)
- [Vagrant](https://www.vagrantup.com/)
- [git-bash](https://git-scm.com/downloads)

# How this works

The [start.bat](start.bat) CMD script:
- Invokes the [console.ps1](console.ps1) Powershell script

The [console.ps1](console.ps1)
- Reads yaml settings from everything under [etc/settings](etc/settings)<br />
  Essentially, the YAML files therein populate the `$Settings` object,<br />
  and each file constitutes a property of said object, with the contents populating<br />
  the property's attributes. Example: <br />
  `$Settings.shells.git` corresponds to the git dictionary object in [etc/settings/shells.yaml](etc/settings/shells.yaml)<br />
  As such, this `$Settings.shells.git.apps` will return a list object comprised <br />
  of dictionary objects with whose keys are `binary` and `command`.
- Launches the default POSIX emulator (git-bash) 

# How to use this project

1. Clone the project
1. Launch the [start.bat](start.bat) CMD script

More documentation to come in the future