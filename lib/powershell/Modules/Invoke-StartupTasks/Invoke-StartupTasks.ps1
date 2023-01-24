Function Invoke-StartupTasks {
    param(
    [Parameter(Mandatory=$False,Position=0)]$TaskList=@()
    )

    begin {
        Invoke-Command -ScriptBlock $Global:InvocationTrace
    }

    process {
        ForEach ($task in $TaskList) {
            if ($task.always_run){
                Invoke-Expression "Invoke-Logger `"$($task.name)`""
                Invoke-Expression $task.command
            } else {
                $task_id =  [math]::abs($task.name.gethashcode())
                $TaskSemaphore = "$($Settings.defaults.infraio_workdir)\post_startup-$($task_id).complete"
                if (-Not $(Test-Path "$TaskSemaphore")) {
                    Invoke-Expression "Invoke-Logger `"$($task.name)`""
                    Invoke-Expression $task.command
                    New-Item "$TaskSemaphore" | Out-Null
                }  
            }
        }
    }

    end 
    {
    }       

}

Set-Alias -Name startup.tasks.run -Value Invoke-StartupTasks