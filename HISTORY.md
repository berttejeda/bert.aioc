=======
History
=======

## Release 2021-01-26 2.0.0

* Major overhaul

## Release 2020-05-21 1.6.1

* Added CredentialManager module for interacting with Windows Credential Manager [becbd2c]
* Added vagrant private and public keys in putty format [e06b51f]
* Fixed bug in machine environment logic [124f609]
* Include psm1 and psd1 file extensions [8369d9b]
* Updated test label [c405725]
* Switch to box created by Bert Tejeda [99f98f4]

## Release 2020-05-21 1.5.6

* Check if Virtualization is enabled in the BIOS [d185e17]

## Release 2020-05-21 1.5.5

* Derive full path to Environment instead of relative path [74d731e]
* Typo in Settings reference [fb53ea9]
* Changed aio vm box [a92044e]
* Cleaned up syntax [50b0ea6]
* Refactor UseGuestControl logic for working with Virtualbox machines [49784ce]
* Add support for provider-specific machine attributes [315cadb]
* Separated lxc tasks out of vm bootstrap role [d884c25]
* Virtualbox: Refactored logic for deriving Machine Definition Posix Path [298ca66]
* Move MachineState logic into provider-specific modules [fe1b820]
* Ensure MachineEnvironment is a fully qualified path when deriving machine definitions [1f7f7e5]
* Ensure we always pass MachineEnvironment when calling List-Machine [d1f0437]
* Suppress output from machine dir creation during VM init [1318869]
* Removed company-specific files and settings [b9c0d5e]

## Release 2020-05-21 1.5.0

* Changed vagrant box for aio vm [4ee1563]
* Refactor TTY logic for Machine-SSH [4929389]
* Added README.md [8dda4bd]
* Removed unused bat script [9a1e7d9]
* Bumped version to 1.4.13 [15861a6]
* Removed tutorials folder from MSI manifest [645d80a]
* Added test machine.init.run [eb383b9]
* Employ garbage collection to avoid scope poisoning [edf8ec6]
* Added function for enabling verbose mode globally [d851e54]
* Moved pip step before bootstrap [9f1f9b8]
* Added safeguard for deriving VM ssh metadata [cbc619e]
* Moved Close-VirtualBoxDisk function out of the init yaml [44fd69f]
* Added rudimentary tracing logic to help with debugging [7d1b149]
* Reworked debug logic for system logger [d06020a]
* Refactored List-Machine logic to avoid unnecessary calls to system commands [fc47eb2]
* Separated facts gathering from lxc bootstrap role [623be69]
* Use markdown for formatting [9fd7831]
* Silently quit when we press q [58445c3]
* Added new function for viewing Machine logs [e46611c]
* AnsiblePlaybook logic for Provision-Machine is now working [6e45cc8]

## Release 2020-04-24 1.4.9

* Updated global_init_dirs [30502d2]
* Default aio console changed to Powershell Core 6.2.4 [091a767]
* Add support for inline credentials when retrieving Tutorials from Bitbucket repos [1e07504]
* Added support for retrieving tutorials via URL 
* Added new helper function for Start-Tutorial module - Parse-TutorialException [4e45fb2]
* Fixed bug in Exercise/Step numbering logic [c24b45b]
* Added support for multi-step exercises [c82e2da]
* Consolidated non-powershell and non-aio shells into a single bat file [aacf775]
* Added functions to enable/disable debugging [0b0178d]
* Added alias to MachineEnvironment Parameter in Get-MachineDefinitions function [e022ce0]
* Fixed regular expressions in dynamic alias/function creation [c2c3888]
* Updated settings for machine provider modules [6d5e39b]
* Added module for creating more robust alias-like functions [5ea624d]
* Moved functions and modules to pre/post directories to compensate for lack of lazy-loading [ec41d21]
* Reverted changes from implementing Execute-Command instead of direct call to ssh.exe [30a7d1e]
* Refactor List-Machine function to more accurately determine VirtualBox VM state [ce8601b]
* Remove Requires header [faff26e]
* Refactored Module Imports [98c4348]

## Release 2020-04-24 1.3.9

* Added support for calling init tasks by TaskNumber and range of TaskNumbers [cceb914]
* Allow VagrantBoxDownloadDirectory to be overridden via machine definition file [bc652b6]
* Add Debug output functionality [3e9d414]
* Addressed bug with non-existing environment folders [078c6b8]
* Refactor to employ Execute-Command function during ssh connection preflight [8584cb4]
* New function for re-importing PS modules [2170ced]
* Improved intermediate file extraction logic [09882a4]
* Updated requirements for ansible role [ee062c9]
* Added support for global-level init actions [c74f9dc]
* Migrated from YAML-formatted tutorial files to Markdown-formatted [f5d6f75]
* Refactored os_type check for virtualbox validations [5dfe797]
* Fixed nopause logic [a16d65a]
* Added portable powershell v6 shell integration [2321921]
* Added Docker lab 02 on building container images [247d922]
* Various functional improvements to Start-Tutorial module [0de5beb]
* Removed Autohotkey objects [b78bf4d]

## Release 2020-04-17 1.3.5

* Updates to docker tutorial [1c1ab53]
* Refactored clear-host logic in Start-Tutorial function [1e1fd4d]
* Refactor machine management functions to mitigate calls to Get-MachineDefinition [4f1082c]
* Refactored pre-flight test logic in SSH-Machine function [14f51e7]
* Refactored Start-Machine function to account for Machine definition input object [6c8372f]
* Converted machine.stop alias to appropriate function [3c46778]
* Fixed incorrect label for List-Machine test [e7cee41]
* Renamed file for aio help function [0d610d3]
* Added missing install_check for VirtualBox [118a413]
* Fail if no machine definitions found for specified machine [0abf179]
* Added new machine definition for barge-os, a DockerMachine alternative [21e2577]
* Refactored tutorials logic [642fe8a]
* Moved machine provider objects to etc\machine\providers [f807e1d]
* Removed company specific settings [f6b605c]
* Added help message for tutorial.start alias [e4b5604]
* Added tutorials folder to include_files [c0c93db]

## Release 2020-04-14 1.3.4

* Ignore consolez settings file and ignore Sublime Text 3 .last-run files [d1337bb]
* Improved SSH-Machine logic [7ec2cbd]
* Improved logic for closing inaccessible VirtualBox  disks [9c72f02]
* Remove inject_insecure_key from aio-vm [950ffc2]
* Initial introduction of garbage collection logic [379c10b]
* Added tutorials and finished Start-Tutorial function [0f09d2d]
* Initial commit [1df6776]
