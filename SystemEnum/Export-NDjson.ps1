function Export-NDjson {
	<#
	.SYNOPSIS
	This function takes the system enumeration functions and exports the results as NDjson

	.DESCRIPTION
	Takes the get-system enumeration function. This then compiles the results in to the ndjson format.
	This is used for import data in to the ELK stack.
	The output has a single line for each section of data (ndjson is delimindated by a new line for each section of data)
	This is still in development. Some functions are yet to be added. 

	.PARAMETER
	None

	.EXAMPLE
	Export-NDjson

	Start the function. The results of this should be piped to an out-file, and saved with the .ndjson extension

	#>

	<# Enable -Confirm and -WhatIf. 
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(
			Mandatory = $true,
			Position = 0,
			ValueFromPipeline = $false,
			ValueFromPipelinebyPropertyName = $true,
			ValueFromRemainingArguments = $true
		)]
		[ValidateNotNullOrEmpty()]
		[string[]] $FromPipeline
	)
	#>

	begin {
		#set the results array. Use this type of array, so can add to array
		#using the fixed list array requires multiple copies of the array be 
		#stored. This does not require multiple copies to add to the array
		[System.Collections.ArrayList]$results = @()
		#set a temporary array to compile the data for each function
		[System.Collections.ArrayList]$tempArray = @()
	}

	process {
		#get the date and time for the results, format in way that the ELK stack requires
		$timestamp = (get-date -format "yyyy-MM-dd hh:mm:ss").tostring()
		#add the opening to start the results
		[void]$results.Add("{")
		#start the results with the ip of the system. This will be our unique key
		[void]$results.add("`"ip`' : $ip")
		#add the timestamp to the results. This is required for import to the ELK stack
		[void]$results.add("`"timestamp`" : $timestamp")
		#set a temporary array to compile the data for each function
		[System.Collections.ArrayList]$tempArray = @()

		#### start system info section
		#put all the properties available in a variable
		$systemInfoProperties = ($systemInformation | Get-Member | Where-Object { $_.MemberType -ne "Method" }).Name
		#get the system information from the function. Using csv so can link the header with the value
		$systemInformation = ConvertFrom-Csv -Delimiter "," -InputObject (systemInformationJson)
		#take each property 		
		foreach ($sysProperty in $systemInfoProperties) {
			#expand the property to get the value
			$sysInfoPropertyValue = $systemInformation | Select-Object -ExpandProperty $sysProperty
			#add the property name and the property value to the results array
			$results.Add("`"$sysProperty`" : `"$sysInfoPropertyValue`"")
		}

		#### start the local users section ####
		$systemLocalUser = systemLocalUser
		#Count the number of local users
		$localUserCount = $systemLocalUser.Count
		#for each of the lines returned in the local users results
		foreach ($user in $systemLocalUser) {
			#before adding the first user (where the local user count is not decreased)
			if ($localUserCount -eq $systemLocalUser.Count) {
				#add the section field heading
				[void]$tempArray.Add( "`"Local Users`" : [") 
			}
			#set the user name in a variable so I don't have to escape so many characters
			$tempLocalUserName = $user.Name
			#set the field showing if user enabled
			$tempLocalUserEnabled = $user."Enabled?"
			#add the user, and if enabled to the results, with a field heading for each
			[void]$tempArray.Add("{`"User`" : `"$tempLocalUserName`",`"Enabled`" : `"$tempLocalUserEnabled`"}")
			#we had added one user, so one less user to add
			$localUserCount--
			#if there are still more users to add
			if ($localUserCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no users left to add
			if ($localUserCount -eq 0) {
				# insert the close group bracket
				[void]$tempArray.Add("]")
			}
			#this will output the array, with a line for each user with the user's status.
			#it will start with the field heading, and opening square bracket. 
			#it will end with the closing square bracket.
		}
		#add the results of the local users to the results array as a single line, type string
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the local groups function ####

		#get the groups from the function
		$systemLocalGroups = systemlocalgroups
		#set the count of the number of groups
		$localGroupsCount = $systemLocalGroups.count

		foreach ($group in $systemLocalGroups) {

			#before adding the first group
			if ($localGroupsCount -eq $systemLocalGroups.Count) {
				[void]$tempArray.Add( "`"Local Groups`" : [") 
			}
			$tempLocalGroupName = $group.Name
			$tempLocalGroupType = $group.ObjectClass
			$tempLocalGroupSource = $group.PrincipalSource
			[void]$tempArray.Add("{`"Group`" : `"$tempLocalGroupName`",`"Type`" : `"$tempLocalGroupType`", `"Source`" : `"$tempLocalGroupSource`" }")
			#we had added one group, so one less group to add
			$localGroupsCount--
			#if there are still more groups to add
			if ($localGroupsCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no groups left to add, insert the close group bracket
			if ($localGroupsCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()
		
		#### start the startup function
		#get the startups from the function
		$systemStartup = systemstartupJson
		#set the count of the number of groups
		$systemStartupCount = $systemStartup.count

		foreach ($startup in $systemStartup) {

			#before adding the first group
			if ($systemStartupCount -eq $systemStartup.Count) {
				[void]$tempArray.Add( "`"Startup`" : [") 
			}
			$tempStartupName = $startup.Name
			$tempStartupCommand = $startup.Command
			$tempStartupLocation = $startup.Location
			$tempStartupUser = $startup.User
			
			[void]$tempArray.Add("{`"Name`" : `"$tempStartupName`",`"Command`" : `"$tempStartupCommand`", `"Location`" : `"$tempStartupLocation`", `"User`" : `"$tempStartupUser`" }")
			#we had added one startup, so one less startup to add
			$localStartupCount--
			#if there are still more startups to add
			if ($localStartupCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no startups left to add, insert the close group bracket
			if ($localStartupCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the netstat function

		#don't use the function; just using netstat command. 
		#TIME_WAIT is not included, because index references are used.
		#will update in the future to search for string to get starting index,
		#instead of hard coded index value. 
		#Hard coding index value may produce errors in output
		#Run the netstat command. n is numerical address, o is owning process id
		$netstatData = (netstat -no | findstr /v "TIME_WAIT")
		#set the start index
		$indexVal = 4
		#adding a test to check if starting on the correct line. May still produce errors
		#if no executeable is listed in the netstat for the connection. Future fix
		#set the contents of the header line
		$headerLine = "  Proto  Local Address          Foreign Address        State           PID"
		#test if the index will line up
		if ($netstatData[($indexVal - 1)] -ne $headerLine) {
			write-host "The index value is not the header" -ForegroundColor Red
			write-host "Run the command (netstat -not | findstr /v `"TIME_WAIT`")"
			[uint16]$indexVal = read-host -prompt "Please input the index value that returns the header" 
			$indexVal++
		}

		#set the length of the output
		$netstatIndexLength = $netstatData.length
		#set the index counter
		[uint16]$currentIndex = $indexVal

		#while the index val is still less than the length
		while ($currentIndex -le ($netstatIndexLength - 1)) {
			#add the header for the temp array
			if ($currentIndex -eq $indexVal) {
				#add the header 
				$tempArray.Add("`"Netstat connections`" : [")
			}
			#"the value is not equal"
			$temp1 = $netstatData[$indexVal]
			#set the process id for the connection
			$currentProcId = ($netstatData[$currentIndex] -split " ")[-1]
			#set the process name from the process id
			$temp2 = (Get-Process -id $currentProcId).Name
			$tempArray.Add("{`"$temp1        $temp2`"}")
			$currentIndex++

			if ($currentIndex -lt $netstatIndexLength) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no users left to add
			if ($currentIndex -eq $netstatIndexLength) {
				# insert the close group bracket
				[void]$tempArray.Add("]")
			}


			#this will output the array, with a line for each user with the user's status.
			#it will start with the field heading, and opening square bracket. 
			#it will end with the closing square bracket.
		}
		#add the results of the local users to the results array as a single line, type string
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		####start the system process function

		#set the information data. Using this instead of function; just removing the output formatting that is displayed
		#in the output file. 
		$systemProcess = systemProcessJson

		#set the count of the number of processes
		$systemProcessCount = $systemProcess.count

		foreach ($process in $systemProcess) {

			#before adding the first process
			if ($systemProcessCount -eq $systemProcess.Count) {
				[void]$tempArray.Add( "`"systemProcess`" : [") 
			}
			$tempProcessName = $process.Name
			$tempProcessId = $process.ProcessId
			$tempProcessParentProcessId = $process.ParentProcessId
			$tempProcessCommand = $process.CommandLine
			
			[void]$tempArray.Add("{`"Name`" : `"$tempProcessName`",`"ProcessId`" : `"$tempProcessId`", `"ParentProcessId`" : `"$tempProcessParentProcessId`", `"Command`" : `"$tempProcessCommand`" }")
			#we had added one process, so one less process to add
			$systemProcessCount--
			#if there are still more processs to add
			if ($systemProcessCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no processs left to add, insert the close group bracket
			if ($systemProcessCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the services function ####

		#set the system services data 
		$systemServiceData = systemService
		#set the number of services that are running
		$systemServiceCount = $systemServiceData.count
		#for each service
		foreach ($service in $systemServiceData) {
			#before adding the first group, add the header for the ndjson output
			if ($systemServiceCount -eq $systemServiceData.Count) {
				[void]$tempArray.Add( "`"Startup`" : [") 
			}
			#set the service name
			$tempServiceName = $service.Name
			#set the service status (this function only returns running services)
			$tempServiceStatus = $service.status
			#set the display (more friendly) name of the service
			$tempServiceDisplayName = $service.DisplayName
			#Add the values to the temporary array, with ndjson formatting
			[void]$tempArray.Add("{`"Name`" : `"$tempServiceName`",`"Status`" : `"$tempServiceStatus`", `"DisplayName`" : `"$tempServiceDisplayName`"}")
			#we had added one service, so one less service to add
			$systemServiceCount--
			#if there are still more services to add
			if ($systemServiceCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no services left to add, insert the close group bracket
			if ($systemServiceCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the powershell history function

		#set the data for the powershell command history
		$systemPwhHistoryData = systemPwhHistoryJson
		#set the number of commands in the list
		$pwshCommandCount = $systemPwhHistoryData.count
		#for each of the commands
		foreach ($psCmd in $systemPwhHistoryData) {
			#if this is the before the first command to be added
			if ($pwshCommandCount -eq $systemPwhHistoryData.count) {
				#add the header to the ndjson data
				[void]$tempArray.Add("`"PowershellCommandHistory`" : [")
			}
			#add the command
			[void]$tempArray.Add("{`"PowershellCommand`" : `"$psCmd`"}")

			#we had added one command, so one less command to add
			$pwshCommandCount--
			#if there are still more commands to add
			if ($pwshCommandCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no commands left to add, insert the close group bracket
			if ($pwshCommandCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the temp file function

		#set the data
		$systemTempData = systemTemp
		#set the count
		$systemTempDataCount = $systemTempData.Count
		#for each of the temporay files
		foreach ($tmpFile in $systemTempData) {
			#if this is the first file
			if ($systemTempDataCount -eq $systemTempData.count) {
				#add the header for the json data
				[void]$tempArray.Add("`"TemporaryFiles`" : [")
			}
			#add the data
			[void]$tempArray.Add("{`"TempFile`" : `"$tmpFile`"}")
			#we had added one temp file, so one less to add
			$systemTempDataCount--
			#if there are still more file paths to add
			if ($systemTempDataCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no file paths left to add, insert the close group bracket
			if ($systemTempDataCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the win temp file function

		#set the data
		$systemWinTempData = systemWinTemp
		#set the count
		$systemWinTempDataCount = $systemWinTempData.Count
		#for each of the temporay files
		foreach ($tmpFile in $systemWinTempData) {
			#if this is the first file
			if ($systemWinTempDataCount -eq $systemWinTempData.count) {
				#add the header for the json data
				[void]$tempArray.Add("`"TemporaryWinFiles`" : [")
			}
			#add the data
			[void]$tempArray.Add("{`"TempWinFile`" : `"$tmpFile`"}")
			#we had added one temp file, so one less to add
			$systemWinTempDataCount--
			#if there are still more file paths to add
			if ($systemWinTempDataCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no file paths left to add, insert the close group bracket
			if ($systemWinTempDataCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the logical drives function ####

		#get the data for the logical drives
		$systemLogicalDrives = systemLogicalDiskJson
		#set the number of drives
		$systemLogicalDrivesCount = $systemLogicalDrives.count
		#for each of the drives
		foreach ($drive in $systemLogicalDrives) {

			#before adding the first process
			if ($systemLogicalDrivesCount -eq $systemLogicalDrives.Count) {
				[void]$tempArray.Add( "`"LogicalDrives`" : [") 
			}
			$tempDriveId = $drive.DeviceId
			$tempDriveFreeSpace = $drive."Free Space (GB)"
			$tempDriveSize = $drive."Size (GB)"
			$tempDriveFilesystem = $drive.FileSystem
			$tempDriveVolumeName = $drive.VolumeName
			$tempDriveType = $drive.DriveType
			
			[void]$tempArray.Add("{`"DeviceId`" : `"$tempDriveId`",`"FreeSpace(GB)`" : `"$tempDriveFreeSpace`", `"Size(GB)`" : `"$tempDriveSize`", `"FileSystem`" : `"$tempDriveFileSystem`", `"VolumeName`" : `"$tempDriveVolumeName`", `"DriveType`" : `"$tempDriveType`" }")
			#we had added one process, so one less process to add
			$systemLogicalDrivesCount--
			#if there are still more processs to add
			if ($systemLogicalDrivesCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no processs left to add, insert the close group bracket
			if ($systemLogicalDrivesCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()

		#### start the scheduled tasks function ####

		#set the data for the tasks
		$systemScheduledTasksData = systemScheduledTasksJson
		#set the number of tasks in the data
		$systemScheduledTasksDataCount = $systemScheduledTasksData.count

		#for each of the scheduledTasks
		foreach ($scheduledTask in $systemScheduledTasksData) {

			#before adding the first process
			if ($systemScheduledTasksDataCount -eq $systemScheduledTasksData.Count) {
				[void]$tempArray.Add( "`"ScheduledTasks`" : [") 
			}
			$tempTaskName = $scheduledTask.Task
			$tempTaskState = $scheduledTask.State
			$tempTaskExecute = $scheduledTask."Execute File"
			
			#add the task to the temporary array
			[void]$tempArray.Add("{`"Task`" : `"$tempTaskName`",`"State`" : `"$tempTaskState`", `"ExecuteFile`" : `"$tempTaskExecute`" }")
			#we had added one task, so one less task to add
			$systemScheduledTasksDataCount--
			#if there are still more tasks to add
			if ($systemScheduledTasksDataCount -gt 0) {
				#add a comma, because we need a comma between groups
				[void]$tempArray.Add(",")
			}
			#if there are no tasks left to add, insert the close group bracket
			if ($systemScheduledTasksDataCount -eq 0) {
				[void]$tempArray.Add("]")
			}
		}
		#add the results to the results array
		[void]$results.Add(($tempArray -join "").ToString())
		#clear the tempArray
		[void]$tempArray.Clear()


		#### FUTURE DEV ####
		#Have not yet added net sessions or route print


		#close function
	}


	end {
		return $results
	}
}

if ($loadingModule) {
	Export-ModuleMember -Function 'Export-NDjson'
}