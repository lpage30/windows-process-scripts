<#
.SYNOPSIS
	Monitor new process creations that meet provided conditions, and call batch file when started.
	
.DESCRIPTION

.PARAMETER UnderDirectory
    (optional) To Match all exe under this directory
	All unique exe | bat | cmd | inf | pif | run | wsh suffix file names are collected, and used in the match command
	(default: all)
	
.PARAMETER CommandLineSubstring
	(optional) Substring to match for commandline of https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-process
	This could be a directory path, or other information to test
	(default: all)

.PARAMETER BatchFilepath
	(Required) Filepath of batch file that takes the following arguments:
		- SessionDateTimeString used for folder names for logs. expected format: 'YYYY_MM_DD.HH_MM_SS'
		- PID  					process Identifier
		- name  				Win32-Process.Name
	Batchfile will be called as a new cmd.exe /k Process

.PARAMETER StartupBatchFileCmdLine
	(optional) Command line to execute before monitoring other services
	cmdline will be called as a new cmd.exe /k Process

.PARAMETER ShutdownBatchFileCmdLine
	(optional) Command lines to execute after stopping the monitoring other service
	cmdlinewill be called as a new cmd.exe /k Process


.EXAMPLE
	- Whenever a new process from is spawned frome VIP source path call BatchFilepath
		monitor-process-conditions-call-batch -UnderDirectory  c:\development\repos\VIP -CommandLineSubstring '.exe' -BatchFilepath log-debugview.bat

.NOTES
#>
[CmdletBinding(DefaultParameterSetName='MonitorProcessConditionsCallBatch')]
param (
	[Parameter(ParameterSetName = 'MonitorProcessConditionsCallBatch',  HelpMessage="Match All executables under this directory")]
	[String]$UnderDirectory,

	[Parameter(ParameterSetName = 'MonitorProcessConditionsCallBatch',  HelpMessage="String to be tested in starting process command lines")]
	[String]$CommandLineSubstring,

	[Parameter(ParameterSetName = 'MonitorProcessConditionsCallBatch',  Mandatory=$true, HelpMessage="Filepath of batch file to call on each process fetch/create")]
	[String]$BatchFilepath,
	
	[Parameter(ParameterSetName = 'MonitorProcessConditionsCallBatch',  HelpMessage="Command line to execute before monitoring other services")]
	[String]$StartupBatchFileCmdLine,
	
	[Parameter(ParameterSetName = 'MonitorProcessConditionsCallBatch',  HelpMessage="Command lines to execute after stopping the monitoring other services")]
	[String]$ShutdownBatchFileCmdLine,

	[Parameter(ParameterSetName = 'MonitorProcessConditionsCallBatch',  HelpMessage="formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session")]
	[String]$SessionDateTimeString = (Get-Date).toString("yyyy_MM_dd.HH_mm_ss")
)

function Main {
	[CmdletBinding(DefaultParameterSetName='Main')]
	param (
		[Parameter(ParameterSetName = 'Main',  HelpMessage="Match All executables under this directory")]
		[String]$UnderDirectory,

		[Parameter(ParameterSetName = 'Main',  HelpMessage="String to be tested in starting process command lines")]
		[String]$CommandLineSubstring,

		[Parameter(ParameterSetName = 'Main',  Mandatory=$true, HelpMessage="Filepath of batch file to call on each process fetch/create")]
		[String]$BatchFilepath,

		[Parameter(ParameterSetName = 'Main',  HelpMessage="Command line to execute before monitoring other services")]
		[String]$StartupBatchFileCmdLine,
		
		[Parameter(ParameterSetName = 'Main',  HelpMessage="Command lines to execute after stopping the monitoring other services")]
		[String]$ShutdownBatchFileCmdLine,

		[Parameter(ParameterSetName = 'Main',  HelpMessage="formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session")]
		[String]$SessionDateTimeString = (Get-Date).toString("yyyy_MM_dd.HH_mm_ss")
			

	)
	$conditionAndMessage = Get-Condition-and-Message -UnderDirectory $UnderDirectory -CommandLineSubstring $CommandLineSubstring
	[String]$Message = ("Call '{0}' for any processes started {1}" -f $BatchFilepath.Substring($BatchFilepath.LastIndexOf("\") + 1), $conditionAndMessage.message)

	Write-Host ("Started({0}) {1}" -f $SessionDateTimeString, $Message)
	try {
		IF (-not(Test-Path $BatchFilepath)) {
			throw [System.IO.FileNotFoundException] ("{0} not found." -f $BatchFilepath)
		}
		[String[]]$startupCmdline = @()
		[String[]]$shutdownCmdline = @()
		if (-not([String]::IsNullOrEmpty($StartupBatchFileCmdLine))) {
			$cmdLine = (($StartupBatchFileCmdLine -Split("`'")) | ForEach-Object {$_.Trim()} | where { $_.Length -gt 0 })
			if ($cmdLine -isnot [array]) {
				$cmdLine = @($cmdLine)
			}
			$startupCmdline = $cmdLine
			Write-Host("Parsed StartupCmdLine: {0}  -> [{1}]" -f $StartupBatchFileCmdLine, ($cmdLine -join "|"))
		}
		if (-not([String]::IsNullOrEmpty($ShutdownBatchFileCmdLine))) {
			$cmdLine = (($ShutdownBatchFileCmdLine -Split("`'")) | ForEach-Object {$_.Trim()} | where { $_.Length -gt 0 })
			if ($cmdLine -isnot [array]) {
				$cmdLine = @($cmdLine)
			}
			$shutdownCmdline = $cmdLine
			Write-Host("Parsed ShutdownCmdLine: {0}  -> [{1}]" -f $ShutdownBatchFileCmdLine, ($cmdLine -join "|"))
		}
		Monitor-Processes-Call-Batch -Condition $conditionAndMessage.condition -ConditionMessage $conditionAndMessage.message -BatchFilepath $BatchFilepath -StartupCmdline $startupCmdline -ShutdownCmdline $shutdownCmdline -SessionDateTimeString $SessionDateTimeString

	} catch {
		Write-Host ("Exception {0}" -f $_)
	}
}

function StartBatchCall {
	param (
		[String]$BatchFilepath,
		[String]$SessionDateTimeString,
		[Int]$ProcessPID,
		[String]$ProcessName,
		[String]$CommandLine
	)
	try {
		Write-Host ("Starting({0}) {1} (session {2}) for Process: {3} ({4}) - ""{5}""" -f (Get-Date).toString("yyyy_MM_dd.HH_mm_ss"), $BatchFilepath.Substring($BatchFilepath.LastIndexOf("\") + 1), $SessionDateTimeString, $ProcessName, $ProcessPID, $CommandLine)
		$process = Start-Process -PassThru -WindowStyle Minimized  -Filepath "cmd.exe" -ArgumentList "/C", $BatchFilepath, $SessionDateTimeString, $ProcessPID, $ProcessName
		return $process.Id
	} catch {
		Write-Host ("Exception Starting {0} for Process: {1} ({2}). {3}" -f $BatchFilepath, $ProcessName, $ProcessPID, $_)
		throw
	}
}

function StopBatchCall {
	param (
		[String]$BatchFilepath,
		[Int]$BatchProcessPID,
		[Int]$ProcessPID,
		[String]$ProcessName,
		[String]$CommandLine

	)
	try {
		Write-Host ("Stopping({0}) {1} ({2}) for Process: {3} ({4}) - ""{5}""" -f (Get-Date).toString("yyyy_MM_dd.HH_mm_ss"), $BatchFilepath.Substring($BatchFilepath.LastIndexOf("\") + 1), $BatchProcessPID, $ProcessName, $ProcessPID, $CommandLine)
		$process = Get-Process -Id $BatchProcessPID
		if ($process -and !$process.started) {
			start-process -WindowStyle Minimized -Filepath "taskkill.exe" -ArgumentList "/PID", $BatchProcessPID, "/T", "/F"
		} 
	} catch {
		Write-Host ("Exception Stopping {0} ({1}) for Process: {2} ({3}). {4}" -f $BatchFilepath, $BatchProcessPID, $ProcessName, $ProcessPID, $_)
		throw
	}
}
function Get-Condition-and-Message{
	[CmdletBinding(DefaultParameterSetName='GetConditionAndMessage')]
	param (
		[Parameter(ParameterSetName = 'GetConditionAndMessage',  HelpMessage="Match All executables under this directory")]
		[String]$UnderDirectory,
		[Parameter(ParameterSetName = 'GetConditionAndMessage',  HelpMessage="String to be tested in starting process command lines")]
		[String]$CommandLineSubstring
	)
	$conditionArray = @()
	$messages = @()
	$executableNames = Get-Executable-Names -UnderDirectory $UnderDirectory

	$conditionArray += "targetInstance isa 'win32_Process'"
	if($executableNames.Length -gt 0) {
		$conditionArray += (Get-TargetInstance-Name-Filter -names $executableNames)
		$messages += ("executable name any of {0} names under {1}" -f $executableNames.Length, $UnderDirectory)
	}
	if ($PSBoundParameters.ContainsKey('CommandLineSubstring') -And $CommandLineSubstring.Length -gt 0) {
		$conditionArray += (Get-TargetInstance-Commandline-Filter -CommandLineSubstring $CommandLineSubstring)
		$messages += ("commandline like {0}" -f $CommandLineSubstring)
	}
	$message = "anywhere"
	if($message.Length -gt 0) {
		$message = ("Where {0}" -f ($messages -join " AND "))
	}
	
	return @{
		condition = ("Where {0}" -f ($conditionArray -join " AND "));
		message = $Message
	}
}

function Monitor-Processes-Call-Batch {
	[CmdletBinding(DefaultParameterSetName='MonitorProcessesCallBatch')]
	param (
		[Parameter(ParameterSetName = 'MonitorProcessesCallBatch',  HelpMessage="WhereClause/Condition for process event query")]
		[String]$Condition,
		[Parameter(ParameterSetName = 'MonitorProcessesCallBatch',  HelpMessage="Message about condition")]
		[String]$ConditionMessage,
	
		[Parameter(ParameterSetName = 'MonitorProcessesCallBatch',  Mandatory=$true, HelpMessage="Filepath of batch file to Start and call")]
		[String]$BatchFilepath,

		[Parameter(ParameterSetName = 'MonitorProcessesCallBatch',  HelpMessage="Command line to execute before monitoring other services")]
		[String[]]$StartupCmdline,
		
		[Parameter(ParameterSetName = 'MonitorProcessesCallBatch',  HelpMessage="Command line to execute after stopping the monitoring other services")]
		[String[]]$ShutdownCmdline,

		[Parameter(ParameterSetName = 'MonitorProcessesCallBatch',  HelpMessage="formatted date and time: `YYYY_MM_DD.HH_MM_SS` of start of overall session")]
		[String]$SessionDateTimeString = (Get-Date).toString("yyyy_MM_dd.HH_mm_ss")
		
	)
	$jobName = "MonitorProcessesCallBatch-BackgroundJob"
	[System.Management.Automation.Job]$job =Start-Job -Name $jobName -ScriptBlock {
		param()
		$startupCommandLine = $using:StartupCmdline
		$shutdownCommandLine = $using:ShutdownCmdline
		$stopBatchCall = [ScriptBlock]::Create($stopBatchCallScriptBlock)
		$whereClause = $using:Condition
		$whereClauseMessage = $using:ConditionMessage
		$batchFilepath = $using:BatchFilepath
		$sessionDateTimeString = $using:SessionDateTimeString
		[PSCustomObject]$processPIDToBatchCallProcessDataMap = @{}
		[PSCustomObject]$batchProcessPIDToBatchCallProcessDataMap = @{}
		
		$processEventWatcherQuery = "select * from __instanceOperationEvent within 1 {0}" -f $whereClause
		try {
			if ($startupCommandLine.Length -gt 0) {
				Write-Host ("Startup: {0}" -f ($startupCommandLine -join ", "))
				Start-Process -PassThru -WindowStyle Minimized  -Filepath "cmd.exe" -ArgumentList (@("/C") + $startupCommandLine)
			}
			$processEventWatcher = New-Object Management.ManagementEventWatcher $processEventWatcherQuery

			# timeout so we have a gap to detect script closure without waiting for an event.
			$processEventWatcher.Options.Timeout = New-Object TimeSpan(0, 0, 3)

			$processEventWatcher.Start()
			
			Write-Host ("Call {0} whenever any process that starts or stops. {0}" -f $batchFilepath, $whereClauseMessage)
			while($true) {
				try {
					$processEvent = $processEventWatcher.waitForNextEvent()
					if($processEvent.__CLASS -eq "__InstanceModificationEvent") {
						continue
					}
				} catch [System.Management.ManagementException] {
					if ($_.Exception.ErrorCode -eq [System.Management.ManagementStatus]::Timedout) {
						continue
					}
				}
				$process = $processEvent.targetInstance
				$processPID = $process.ProcessId
				$processName = [io.path]::GetFileNameWithoutExtension($process.Name)
				$commandLine = $process.CommandLine
				
				if($batchProcessPIDToBatchCallProcessDataMap.ContainsKey($processPID)) {
					$batchProcessPIDToBatchCallProcessDataMap.Remove($processPID)
					continue
				}
					

				try {
					if ($processEvent.__CLASS -eq "__InstanceDeletionEvent") {
						if ($processPIDToBatchCallProcessDataMap.ContainsKey($processPID)) {
							$batchProcessData = $processPIDToBatchCallProcessDataMap[$processPID]
							$processPIDToBatchCallProcessDataMap.Remove($processPID)
							Invoke-Command $stopBatchCall -ArgumentList $batchFilepath, $batchProcessData.batchProcessPID, $processPID, $batchProcessData.processName, $batchProcessData.commandLine
						}
						continue
					} 
					if ($processEvent.__CLASS -eq "__InstanceCreationEvent") {
						$batchProcessPID = Invoke-Command $startBatchCall -ArgumentList $batchFilepath, $sessionDateTimeString, $processPID, $processName, $commandLine
						$batchProcessPIDToBatchCallProcessDataMap.Add($batchProcessPID, @{
							processPID = $processPID;
							processName = $processName;
							commandLine = $commandLine
						})
						$processPIDToBatchCallProcessDataMap.Add($processPID, @{
							batchProcessPID = $batchProcessPID;
							processName = $processName;
							commandLine = $commandLine
						})
						continue
					} 
					
					Write-Host("Unsupported Event {0} for process" -f $processEvent.__CLASS, $processName)
				} catch {
					Write-Error ("Failed Processing {0} {1}({2}). {3}" -f $processEvent.__CLASS, $processName, $processPID, $process.Name, $_)
					throw
				}
			
			}
			Write-Host ("Finished Running")
		} catch {
			Write-Error ("Failed running Process EventWatcher {0}   {1}" -f $processEventWatcherQuery, $_ )
			throw
		} finally {
			Write-Host("Exiting Job {0} with {1} started batch calls" -f $jobName, $processPIDToBatchCallProcessDataMap.Count)
			ForEach($processPID in $processPIDToBatchCallProcessDataMap.Keys) {
				$batchProcessData = $processPIDToBatchCallProcessDataMap[$processPID]
				Invoke-Command $stopBatchCall -ArgumentList $batchFilepath, $batchProcessData.batchProcessPID, $processPID, $batchProcessData.processName
			}
			if ($shutdownCommandLine.Length -gt 0) {
				Write-Host ("Shutdown: {0}" -f ($shutdownCommandLine -join ", "))
				Start-Process -PassThru -WindowStyle Minimized  -Filepath "cmd.exe" -ArgumentList (@("/C") + $shutdownCommandLine)				
			}
			
		}
	}
	Receive-Job -Name $jobName -wait -AutoRemove 
}
function Get-Executable-Names{
	[CmdletBinding(DefaultParameterSetName='GetExecutableNames')]
	param (
		[Parameter(ParameterSetName = 'GetExecutableNames',  HelpMessage="Match All executables under this directory")]
		[String]$UnderDirectory
	)
	$names = @()
	if ($PSBoundParameters.ContainsKey('UnderDirectory') -And $UnderDirectory.Length -gt 0 -And (Test-Path -Path $UnderDirectory)) {
		$uniqueNames = [System.Collections.Generic.HashSet[string]]::new()
		Write-Host ("Collecting names of executables under {0}..." -f $UnderDirectory)
		Get-Childitem -Path $UnderDirectory -Include *.exe,*.bat,*.com,*.inf,*.pif,*.run,*.wsh -File -Recurse | ForEach-Object {
			if($uniqueNames.Add($_.Name)) {
				$names += $_.Name
				if($names.Length % 10 -eq 0) {
					Write-Host ("{0} names collected..." -f $names.Length) | Out-Host
				}					
			}
		}
		Write-Host ("Collected {0} names." -f $names.Length)
	}
	return $names
}

function Get-TargetInstance-Commandline-Filter{
	[CmdletBinding(DefaultParameterSetName='TargetInstanceCommandLine')]
	param (
		[Parameter(ParameterSetName = 'TargetInstanceCommandLine',  HelpMessage="String to be tested in starting process command lines")]
		[String]$CommandLineSubstring
	)
	if ($PSBoundParameters.ContainsKey('CommandLineSubstring') -And $CommandLineSubstring.Length -gt 0) {
		return "(targetInstance.CommandLine like '%{0}%')" -f $CommandLineSubstring.Replace("*", "%")
	}
	return $null
}
	
function Get-TargetInstance-Name-Filter{
	[CmdletBinding(DefaultParameterSetName='TargetInstanceName')]
	param (
		[Parameter(ParameterSetName = 'TargetInstanceName',  HelpMessage="Array of executable names for constructing filter")]
		[String[]]$names
	)
	$conditionArray = @()
	foreach($name in $names) {
		$conditionArray += ("targetInstance.Name = '{0}'" -f $name)
	}
	if($conditionArray.Length -gt 0) {
		return ("({0})" -f ($conditionArray -join " OR "))
	}
	return $null
}
Main  -UnderDirectory $UnderDirectory -CommandLineSubstring $CommandLineSubstring -BatchFilepath $BatchFilepath -StartupBatchFileCmdLine $StartupBatchFileCmdLine -ShutdownBatchFileCmdLine $ShutdownBatchFileCmdLine -SessionDateTimeString $SessionDateTimeString