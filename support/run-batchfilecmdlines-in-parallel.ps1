<#
.SYNOPSIS
	Run batchfile command lines in parallel
	
.DESCRIPTION

.PARAMETER BatchFileCmdLines
    (Required) 1 or more command lines to execute in parallel

.EXAMPLE
	set line1="\"cmd\" \"one\" \"two three four\" \"three four five\""
	set line2="\"cmd2\" \"one\" \"two three four\" \"three four five\""
	powershell .\run-batchfilecmdlines-in-parallel.ps1 -BatchFileCmdLines '%line1%','%line2%
	it will receive a BatchFileCmdLines array of the following:
	$BatchFileCmdLines[0] == '"cmd" "one" "two three four" "three four five"'
	$BatchFileCmdLines[1] == '"cmd2" "one" "two three four" "three four five"'

.NOTES
#>
[CmdletBinding()]
param (
	[Parameter(Mandatory=$true, HelpMessage="1 or more command lines to execute in parallel")]
	[String[]]$BatchFileCmdLines

)
<#
	convert the following to 2 arrays of arrays
	$BatchFileCmdLines[0] == "'cmd''one''two three four''three four five'"
	$BatchFileCmdLines[1] == "'cmd2''one''two three four''three four five'"
	
	$CommandLines[0] == @('cmd', 'one', 'two three four', 'three four five')
	$CommandLines[1] == @('cmd2', 'one', 'two three four', 'three four five')
#>
[String[][]]$CommandLines = @()
foreach($batchFileCmdLine in $BatchFileCmdLines) {
	$cmdLine = (($batchFileCmdLine -Split("`'")) | ForEach-Object {$_.Trim()} | where { $_.Length -gt 0 })
	if ($cmdLine -isnot [array]) {
		$cmdLine = @($cmdLine)
	}
	$CommandLines += ,$cmdLine
}

$jobName = "RunBatchfilesInParallel-BackgroundJob"
[System.Management.Automation.Job]$job =Start-Job -Name $jobName -ScriptBlock {
	param()
	[String[][]]$commandLines = $using:CommandLines
	foreach($commandLine in $commandLines) {
		Start-Process -PassThru -WindowStyle Minimized  -Filepath "cmd.exe" -ArgumentList (@("/C") + $commandLine)
	}
}
Receive-Job -Name $jobName -wait -AutoRemove
