@echo off
setlocal
IF "%2" == "" GOTO :HELP
GOTO :START

:HELP
echo "USAGE: %0 <process-condition> <batch-file-to-call> [<startup-batch-command-line> [<shutdown-batch-command-line> [<session-date-time-string>]]]"
echo "Whenever a program meeting <program-condition> starts, call <batch-file-to-call> with following information:"
echo "	`CALL <batch-file-to-call> <SessionDateTimeString> <process-PID> <process-name>`  "
echo "`<SessionDateTimeString>` - formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session  "
echo "`<process-PID>` - process Identifier of process that started  "
echo "`<process-name>` - Win32-Process.Name of process that started  "
echo "`<process-condition> - can be:  "
echo "  `directory-path` - whenever an executable file under this directory starts call `<batch-file-to-call>` with its information  "
echo "  `process-command-line-substring` - whenever a process containing this substring starts call `<batch-file-to-call>` with its information  "
echo "`<batch-file-to-call>` - a batch file that will be called in its own process whenever a process starts and killed when that process ends.  "
echo "`<startup-batch-command-line>` - of forms `""'<batchfile>''<arg1>''<arg2>''...'""` or `""<batchfile>""` , called once before monitoring processes.  "
echo "`<shutdown-batch-command-line>` -of forms `""'<batchfile>''<arg1>''<arg2>''...'""` or ""<batchfile>""`, called once when process monitoring ends."
echo "`<session-date-time-string>` - formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session"

GOTO :EOF

:START
set conditionArg=%~1
set batchfileArg=%~2
set startupBatchFileCmdLine=%3
set shutdownBatchFileCmdLine=%4
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

IF NOT "%startupBatchFileCmdLine%" == "" (
	set startupCmdLine=-StartupBatchFileCmdLine %startupBatchFileCmdLine:\=\\%
) ELSE (
	set startupCmdLine=
)

IF NOT "%shutdownBatchFileCmdLine%" == "" (
	set shutdownCmdLine=-ShutdownBatchFileCmdLine %shutdownBatchFileCmdLine:\=\\%
) ELSE (
	set shutdownCmdLine=
)

IF NOT "%sessionDateTimeStringArg%" == "" (
	set sessionDateTimeString=-SessionDateTimeString %sessionDateTimeStringArg%
) ELSE (
	set sessionDateTimeString=
)


echo "calling %~dp0.\support\monitor-process-conditions-call-batch.ps1 %condition% %batchFile% %startupCmdLine% %shutdownCmdLine% %sessionDateTimeString%"

call powershell.exe %~dp0.\support\monitor-process-conditions-call-batch.ps1 %condition% %batchFile% %startupCmdLine% %shutdownCmdLine% %sessionDateTimeString%

endlocal
