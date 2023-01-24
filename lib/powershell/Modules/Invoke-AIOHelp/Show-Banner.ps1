function Show-Banner {

    param(
    [switch]$AllCommands
    )   

    begin {
        SafelyClear-Host
        Write-Host "++++++++++++++++++++++++++++++++" -ForegroundColor Yellow -BackgroundColor Black
        Write-Host "All-In-One-VM Command Console" -ForegroundColor Green -BackgroundColor Black
        Write-Host -NoNewLine "If this is your first time using this tool," -ForegroundColor Magenta -BackgroundColor Black
        Write-Host -NoNewLine " enter in the command: " -ForegroundColor Magenta -BackgroundColor Black
        Write-Host "Start-Tutorial" -ForegroundColor Blue -BackgroundColor Black
        $AvailableCommands = Get-Command | Where-Object{$_.Source -in $AIOLoadedModules -and $_.Name -match "[\w]+\."}
        $AvailableCommands += Get-Alias | Where-Object{$_.Source -in $AIOLoadedModules -and $_.Name -match "[\w]+\."}
        $BannerOutput = "Name,Syntax`n"
    }

    process {

        ForEach ($Command in $AvailableCommands) {
          if ($Command.CommandType -eq "Alias") {
            $ParentCommand = $Command.ResolvedCommand
            $CommandSyntax = (Get-Help $Command.Name).Synopsis.ToString().Trim() -Replace($ParentCommand,$Command.Name)
          } else {
            $CommandSyntax = (Get-Help $Command.Name).Synopsis.ToString().Trim()
          }
          $BannerOutput += "$($Command.Name),$CommandSyntax`n"
        }

    }

    end {
        Write-Host -NoNewLine "Enter in any of " -ForegroundColor Magenta -BackgroundColor Black
        Write-Host -NoNewLine "Show-Banner, aio.help or aio.banner" -ForegroundColor Blue -BackgroundColor Black
        Write-Host " for helpful tips and informational messages" -ForegroundColor Magenta -BackgroundColor Black
        Write-Host "Quick Start:" -ForegroundColor Green -BackgroundColor Black
@"    
| Action                                   | Command                                                              |
|:-----------------------------------------|:---------------------------------------------------------------------|
| Start the AIO Machine                    | machine.start.aio                                                    |
| Restart the AIO Machine                  | machine.restart.aio                                                  |
| Stop the AIO Machine                     | machine.stop.aio                                                     |
| Destroy the AIO Machine                  | machine.destroy.aio                                                  |
| Invoke an SSH session to the AIO Machine | machine.ssh.aio                                                      |
| Change/Set MachineEnvironment            | environment.set [[-MachineEnvironment] <path\to\environment\folder>] |
| Reset MachineEnvironment back to default | environment.reset                                                    |
| List Machines                            | machine.list                                                         |
| List A Single Machine                    | machine.list [[-MachineName] <NameOfMachine>]                        |
| Create a Machine                         | machine.create [-MachineName] <NameOfMachine>                        |
| Destroy a Machine                        | machine.destroy [-MachineName] <NameOfMachine>                       |
| Start a Machine                          | machine.start [-MachineName] <NameOfMachine>                         |
| Start an SSH Session to a Machine        | machine.ssh [-MachineName] <NameOfMachine>                           |
| Stop a Machine                           | machine.stop [-MachineName] <NameOfMachine>                          |
| Restart a Machine                        | machine.restart [-MachineName] <NameOfMachine>                       |
| View Machine logs                        | machine.logs [-MachineName] <NameOfMachine>                          |
"@
        Write-Host -NoNewLine "To Display ALL available commands, invoke any of the banner commands with the" -ForegroundColor Magenta -BackgroundColor Black
        Write-Host -NoNewLine " -AllCommands" -ForegroundColor Blue -BackgroundColor Black
        Write-Host " flag"
        Write-Host "++++++++++++++++++++++++++++++++" -ForegroundColor Yellow -BackgroundColor Black
        if ($AllCommands){
            Write-Host "# All Available Commands:" -ForegroundColor Green -BackgroundColor Black
            $BannerOutput | ConvertFrom-CSV
        }
    }
} 

Set-Alias -Name aio.banner -Value Show-Banner
Set-Alias -Name aio.help -Value Show-Banner