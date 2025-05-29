@echo off
echo "process-scripts scripts-as-api"
:: global variables for specific scripts that others could use
echo "setx ON_MONITORED_PROCESSES_CALL_BATCHFILE_BAT"
setx ON_MONITORED_PROCESSES_CALL_BATCHFILE_BAT "%~dp0on-monitored-processes-call-batchfile.bat"

echo "setx RUN_BATCHFILES_AS_PARALLEL_PROCESSES_BAT"
setx RUN_BATCHFILES_AS_PARALLEL_PROCESSES_BAT "%~dp0run-batchfiles-as-parallel-processes.bat"
