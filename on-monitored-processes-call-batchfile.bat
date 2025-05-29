@echo off
setlocal
IF "%2" == "" GOTO :HELP

set conditionArg=%~1
set batchfileArg=%~2
set startupBatchfileArg=%~3
set shutdownBatchfileArg=%~4
set sessionDateTimeStringArg=%~5
IF EXIST "%conditionArg%\" (
	set condition=-UnderDirectory %conditionArg:\=\\%
) ELSE (
	set condition=-CommandLineSubstring "%conditionArg%"
)

IF NOT EXIST "%batchfileArg%" (
	echo %batchfileArg% does not EXIST
	GOTO :HELP
)
set batchFile=-BatchFilepath %batchfileArg:\=\\%

IF EXIST "%startupBatchfileArg%" (
	set startupBatchfile=-StartupBatchFilepath %startupBatchfileArg:\=\\%
) ELSE (
	set startupBatchfile=
)

IF EXIST "%shutdownBatchfileArg%" (
	set shutdownBatchfile=-ShutdownBatchFilepath %shutdownBatchfileArg:\=\\%
) ELSE (
	set shutdownBatchfile=
)

IF NOT "%sessionDateTimeStringArg%" == "" (
	set sessionDateTimeString=-SessionDateTimeString %sessionDateTimeStringArg%
) ELSE (
	set sessionDateTimeString=
)


echo "calling %~dp0.\support\monitor-process-conditions-call-batch.ps1 %condition% %batchFile% %startupBatchfile% %shutdownBatchfile% %sessionDateTimeString%"

call powershell.exe %~dp0.\support\monitor-process-conditions-call-batch.ps1 %condition% %batchFile% %startupBatchfile% %shutdownBatchfile% %sessionDateTimeString%
GOTO :EOF



:HELP
echo "USAGE: %0 <process-condition> <batch-file-to-call> [<startup-batch-file-to-call> [<shutdown-batch-file-to-call> [<session-date-time-string>]]]"
echo "Whenever a program meeting <program-condition> starts, call <batch-file-to-call> with following information:"
echo "	`CALL <batch-file-to-call> <SessionDateTimeString> <process-PID> <process-name>`  "
echo "`<SessionDateTimeString>` - formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session  "
echo "`<process-PID>` - process Identifier of process that started  "
echo "`<process-name>` - Win32-Process.Name of process that started  "
echo "`<process-condition> - can be:  "
echo "  `directory-path` - whenever an executable file under this directory starts call `<batch-file-to-call>` with its information  "
echo "  `process-command-line-substring` - whenever a process containing this substring starts call `<batch-file-to-call>` with its information  "
echo "`<batch-file-to-call>` - a batch file that will be called in its own process whenever a process starts and killed when that process ends.  "
echo "`<startup-batch-file-to-call>` - a batch file that will be called once before monitoring processes.  "
echo "`<shutdown-batch-file-to-call>` - a batch file that will be called once when process monitoring ends."
echo "`<session-date-time-string>` - formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session"

GOTO :EOF
endlocal
