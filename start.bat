echo off
echo ; set +v # > NUL
echo ; function GOTO { true; } # > NUL
GOTO WIN
# Bash start
pwsh -noprofile -noexit -executionpolicy bypass console.ps1
# Bash end
exit 0
 
:WIN

REM Batch start
setlocal EnableDelayedExpansion
(set \n=^
%=Do not remove this line=%
)

cd %~dp0
start "" "%~dp0\Programs\ConsoleZ\console.exe"

REM Batch end

