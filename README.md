# windows-process-scripts
Batch files and powershell scripts that, when called, are long lived to monitor processes, that fit a provided condition, that start/end
and calling of batch files for each monitored process that starts (or ends)

Also includes combining of scripts for parallel processing under one parent process

## USAGE
- `on-monitored-processes-call-batchfile.bat <process-condition> <batch-file-to-call> [<startup-batch-file-to-call> [<shutdown-batch-file-to-call>]]`  
Whenever a program meeting <program-condition> starts, call <batch-file-to-call> with following information:  
  - `CALL <batch-file-to-call>  <SessionDateTimeString> <process-PID>  <process-name>`  

    - `<SessionDateTimeString>` - formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session  
    - `<process-PID>` - process Identifier of process that started  
    - `<process-name>` - Win32-Process.Name of process that started  
  - `<process-condition>` can be:  
    - `directory-path` - whenever an executable file under this directory starts call 
    - `<batch-file-to-call>` with its information  
  - `process-command-line-substring` - whenever a process containing this substring starts call 
  - `<batch-file-to-call>` - a batch file that will be called in its own process whenever a process starts and killed when that process ends.  
  - `<startup-batch-file-to-call>` - a batch file that will be called once before monitoring processes.  
  - `<shutdown-batch-file-to-call>` - a batch file that will be called once when process monitoring ends.

- `run-batchfiles-as-parallel-processes.bat <batch-command-line-1> [...<batch-command-line-N>]`  
run complete batchfile commands each as their own process in parallel.
  - `<batch-command-line>` should be enclosed in quotes to retain the command followed by any arguments

- `render-force-quit-dialog.bat`  
run to produce list of processes to force quit (similar to MAC force quit). You can toggle between list and tree views of processes.