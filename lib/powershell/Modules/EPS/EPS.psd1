@{ 
    
# Script module or binary module file associated with this manifest.
ModuleToProcess = 'EPS.psm1' # using ModuleToProcess for PS 2.0 compatibility

# Version number of this module.
ModuleVersion = '1.0.0'

# ID used to uniquely identify this module
GUID = 'f24c1ca7-e4fd-4b7d-8ff8-75ef7f7ea162'

# Author of this module
Author = 'Dave Wu, Dominique Broeglin'

# Copyright statement for this module
Copyright = '(c) 2014 Dave Wu. All rights reserved.'

# Description of the functionality provided by this module
Description = @'
EPS (Embedded PowerShell), inspired by ERB (see https://en.wikipedia.org/wiki/ERuby), is a templating language that embeds PowerShell code into a text document. It is conceptually and syntactically similar to ERB for Ruby or Twig (see http://twig.sensiolabs.org/) for PHP.
EPS can be used to generate any kind of text. The example below illustrates generating plain text, but it could be used to generate HTML in a web application or PowerShell code as in the Forge Module generator (see https://github.com/dbroeglin/Forge.Module)
'@

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = 'Invoke-EpsTemplate'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PowerShell', 'Template'

        # A URL to the license for this module.
        LicenseUri = 'https://opensource.org/licenses/MIT'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/straightdave/eps'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

