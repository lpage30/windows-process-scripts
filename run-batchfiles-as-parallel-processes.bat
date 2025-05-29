@echo off
setlocal enabledelayedexpansion
if "%1" == "" (
	echo "USAGE: %0 "<batch-command-line-1>" ... "<batch-command-line-N>""
	echo "Executes batch command-lines 1 - N in parallel via powershell start-processes held by a single job"
	echo "<batch-command-line>  - should be enclosed in quotes to retain the command followed by any arguments"
	GOTO :EOF
)
set batchFileCmdLines=%1
:NEXT_BATCH_FILE_CMD_LINE
shift
IF "%1" == "" GOTO :EXECUTE
set batchFileCmdLines=!batchFileCmdLines!,%1
GOTO :NEXT_BATCH_FILE_CMD_LINE

:EXECUTE
call powershell %~dp0.\support\run-batchfilecmdlines-in-parallel.ps1 -BatchFileCmdLines !batchFileCmdLines!
endlocal