function Get-System {
    <#
	.SYNOPSIS
	This function enumerates system information
		 
	.DESCRIPTION
	This function enumerates system information. 
    The results are then output to a file.  
    The function takes a list of computers (ips) to enumerate, and a list 
    detailing which information you require of the system. 

    The results are then output to a text document

    #### future functionality ####
    - working on format to output for json, to be ingested in to siem. 

	.PARAMETER ipList
	ip - an ip addresses, for the system that is to be enumerated; 

    "10.10.10.15"
	
    Will be used to enumerate remote system, or identify local system that was enumerated.  

    .PARAMETER functionOptionList
    
    A list of the information that you require from the system. 
    Choose any/all from the following list, paste in to txt document and save.

    systemLocalUser 
    systemLocalGroups 
    systemStartup 
    systemInformation 
    systemNetstat 
    systemProcesses 
    systemRoute
    systemSessions 
    systemService 
    systemPwhHistory 
    systemTemp 
    systemWinTemp 
    systemLogicalDisk
    systemScheduledTasks

	.EXAMPLE
	Get-System -ipList "192.168.1.1" -functionOptionList "c:\function_option_list.txt"

    Manually listing the ip and path to the switch options

	#>

    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false)]
        [String[]]$ip,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false)]
        [String]$functionOptionList


    )

    #The BEGIN block runs once, before the first item in the collection. 
    BEGIN {
        #if the function option list is empty
        if ($null -eq $functionOptionList) {
            #set the function to run all system enumeration information
            $switchOptions = 
            "systemLocalUser", 
            "systemLocalGroups", 
            "systemStartup",
            "systemInformation", 
            "systemNetstat", 
            "systemProcesses", 
            "systemRoute", 
            "systemnUsers", 
            "systemSessions", 
            "systemService", 
            "systemPwhHistory", 
            "systemTemp", 
            "systemWinTemp", 
            "systemLogicalDisk"
            "systemScheduledTasks"
        }
        #if the path is supplied, get the switch options from the txt file
        else {
            $switchOptions = Get-Content $functionOptionList
        }
    }
    #The PROCESS block runs once for each item in the collection
    PROCESS {

        function systemLocalUser {
            Set-Variable -Name PSversionU -Value $null
            $PSversionU = ((Get-Host).Version).Major
            if ($PSversionU -gt 2) {
                Get-LocalUser | 
                Where-Object { $_.Enabled -eq $true } |
                Select-Object @{label = "ip"; expression = { $ip } },
                Name, @{label  = "Enabled?";
                    expression = { if ($_.Enabled -eq $true) { "Enabled" }
                        else {
                            "Disabled"
                        }
                    }
                } |
                Out-String
            }
            else {
                wmic useraccount list brief | Out-String
            }
        }

        function systemLocalGroups {
            $PSversionG = ((Get-Host).Version).Major
            IF ($PSversionG -gt 2) {
                $LocalGroup = (Get-LocalGroup).Name
                $LocalGroup | % {
                    Get-LocalGroupMember -Group $_
                } | Out-String
            }
            ELSE {
                wmic path win32_groupuser | out-string
            }
        }

        function systemStartup {
            $startupLocationsNames = (Get-Wmiobject Win32_startupcommand |  
                Select-Object Name, @{label = "command"; expression = { $_.Command } },
                @{label = "Location"; expression = { $_.Location } },
                @{label = "User"; expression = { $_.User } } |
                Group-Object -Property Location -NoElement).Name

            $hash = Get-Wmiobject Win32_startupcommand |  
            Select-Object Name, 
            @{label = "command"; expression = { $_.Command } }, 
            @{label = "Location"; expression = { $_.Location } }, 
            @{label = "User"; expression = { $_.User } } | 
            Group-Object -Property Location -AsHashTable -AsString

            $startupTable = foreach ($startUpLocation in $startupLocationsNames) {

                Write-Output "################ Location [$startupLocation] ################"
                $hash.$startupLocation | Select-Object Name, User, Command | Format-Table -AutoSize -Wrap
                Write-Output "`n"    
            }
            $startupTable
        }

        function systemInformation { systeminfo | out-string }

        function systemNetstat { netstat -natob | out-string }
 
        function systemProcess { Get-WmiObject Win32_Process | Select-Object Name, ProcessId, ParentProcessId, CommandLine | ft -AutoSize -Wrap | out-string }
 
        function systemRoute { route print | out-string }
 
        function systemSessions { net sessions | out-string }
 
        function systemService {
            get-service | 
            where-object { $_.Status -eq "Running" } |
            out-string
        }

        function systemPwhHistory {
 
            $histPath = Split-Path -Path (Get-PSReadlineOption).HistorySavePath
            $histtxt = (Get-ChildItem $histPath).Name
            $count = $histtxt.count

            if ($count -gt 1) { 
                #"the count of histtxt is greater than 1"
                #take each of the file names that are returned
                foreach ($txtfile in $histtxt) {
                    #show the file name that is being returned each loop
                    #"the file name in current loop is $txtfile"
                    #set the path for the current file
                    $currentFilePath = $histPath + "\" + $txtfile
                    #show the path set for the current file
                    #$currentFilePath
                    #get the content of the current file
                    "`n ######## History from the file $txtfile ########"
                    Get-Content $currentFilePath | Where-Object { $_.trim() -ne "" } | Out-String
        
                } 
            }
            #if there is just one file
            else {
                #set the file path
                $currentFilePath = $histPath + "\" + $histtxt
                #get the content from the file
                Get-Content $currentFilePath | Where-Object { $_.trim() -ne "" } | Out-String
            }

        }
 
        function systemTemp { cmd /c "dir %TEMP% /b /s /a-d" | out-string }
 
        function systemWinTemp { cmd /c "dir C:\Windows\Temp /b /s /a-d" | out-string }
 
        function systemLogicalDisk {

            $gbFreeSpace = @{Name = "Free Space (GB)"; Expression = { [math]::round($_.freespace / 1GB, 2) } }

            $gbSize = @{Name = "Size (GB)"; Expression = { [math]::round($_.size / 1GB, 2) } }

            $DriveType = @{
                Name       = 'DriveType'
                Expression = {
                    # property is an array, so process all values
                    $value = $_.DriveType
    
                    switch ([int]$value) {
                        0 { 'Unknown' }
                        1 { 'No Root Directory' }
                        2 { 'Removable Disk' }
                        3 { 'Local Disk' }
                        4 { 'Network Drive' }
                        5 { 'Compact Disc' }
                        6 { 'RAM Disk' }
                        default { "$value" }
                    }
      
                }  
            }

            Get-CimInstance Win32_LogicalDisk | 
            Select-Object DeviceID, $gbFreeSpace, $gbSize, FileSystem, VolumeName, $DriveType | 
            Format-Table -AutoSize | Out-String 
        }

        function systemScheduledTasks {
            Get-ScheduledTask  |
            Select-Object -Property TaskName, State -ExpandProperty Actions |
            select-object @{label = "Task"; expression = { $_.TaskName } },
            @{label = "State"; expression = { $_.State } },
            @{label = "Execute file"; expression = { $_.Execute } } | 
            Sort-Object State | Format-Table -AutoSize | Out-String 
        }

        ######################################################### Header ##########################################################################

        if ($null -ne $switchOptions) {

            [void]$results.Add(("`n ################ System enum at " + (Get-date).ToString() + " for machine " + $ip + " ################ `n"))

        }
        ######################################################### Switch ##########################################################################

        switch ($switchOptions) {

            systemLocalUser {
                [void]$results.Add("`n######################### Local user for machine " + $ip + " ################ `n")
                [void]$results.Add((systemLocalUser))
            }

            systemLocalGroups {
                [void]$results.Add("`n######################### Local groups for machine " + $ip + " ################ `n")
                [void]$results.Add((systemLocalGroups))
            }

            systemStartup {
                [void]$results.Add("########################## Start-up for machine " + $ip + "##############################`n")
                [void]$results.Add((systemStartup))
            }

            systemInformation {
                [void]$results.Add("`n##########################System information for machine " + $ip + "#############################`n")
                [void]$results.Add((systeminformation))
            }

            systemNetstat {
                [void]$results.Add("`n##########################Netstat for machine " + $ip + "#############################`n")
                [void]$results.Add((systemNetstat))
            }

            systemProcesses {
                [void]$results.Add("`n##########################Processes for machine " + $ip + "#############################`n")
                [void]$results.Add((systemProcess))
            }

            systemRoute {
                [void]$results.Add("`n##########################Routes for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemRoute))
            }

            systemSessions {
                [void]$results.Add("`n##########################Sessions for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemSessions))
            }

            systemService {
                [void]$results.Add("`n##########################Running services for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemService))
            }

            systemPwhHistory {
                [void]$results.Add("`n##########################PowerShell history for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemPwhHistory))
            }

            systemTemp {
                [void]$results.Add("`n##########################TEMP contents for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemTemp))
            }

            systemWinTemp {
                [void]$results.Add("`n##########################Windows temp contents for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemWinTemp))
            }

            systemLogicalDisk {
                [void]$results.Add("`n##########################Disk information for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemLogicalDisk))
            }

            systemScheduledTasks {
                [void]$results.Add("`n##########################Scheduled tasks for machine " + $ip + "#############################`n") 
                [void]$results.Add((systemScheduledTasks))
            }


        }

        ######################################################### Output ##########################################################################

        $resCount = $results.count

        if ($resCount -eq 0) {
            Write-host "Complete with" -NoNewline
            Write-host " [$resCount] " -foregroundcolor Red -NoNewline 
            Write-host "results."
            "No systems were enumerated."
            "Please check for errors if results should be returned"
        }

        else {
            "There are $resCount results."
            $results
        }
    }
    #The END block also runs once, after every item in the collection has been processes
    END {
    }
}		


if ($loadingModule) {
	Export-ModuleMember -Function 'Get-System'
}