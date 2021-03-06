﻿function Get-System {
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

    .PARAMETER functionOptionListPath
    
    A path to a list of the names of the functions that you wish to run. 

	.EXAMPLE
	
    Get-System -ipList "192.168.1.1" -functionOptionListPath "c:\function_option_list.txt"
    
    Manually listing the ip and path to the switch options

	#>

    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 0)]
        [String[]]$ip,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            Position = 1)]
        [String[]]$switchOptions,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false)]
        [String]$functionOptionListPath
    )

    #The BEGIN block runs once, before the first item in the collection. 
    BEGIN {
        #results array
        [System.Collections.ArrayList]$results = @()
        $systemPSversion = ($PSVersionTable.PSVersion.Major | Out-String).trim()
    }
    #The PROCESS block runs once for each item in the collection
    PROCESS {

        function systemLocalUser {
            write-host "systemlocaluser is running"
              
            if ($systemPSversion -gt 2) {
                Get-LocalUser | Where-Object { $_.Enabled -eq $true } | 
                Select-Object @{label = "ip"; expression = { $ip } }, Name, 
                @{label = "Enabled?"; expression = { 
                        if ($_.Enabled -eq $true) { "Enabled" }
                        else {
                            "Disabled"
                        }
                    } 
                }  
            } 
    
            if ($systemPSversion -le 2) {
            
                $systemLocalUserWmic = wmic useraccount get Name, Domain, LocalAccount, Status -format:list | Where-Object { $_ -ne "" }
            
                $i = 0
                $length = $systemLocalUserWmic.Count

                $localWmicOut = 
                while ($i -lt $length) {
                    $name = $systemLocalUserWmic[($i + 2)].split("=")[1]
                    $domain = $systemLocalUserWmic[$i].split("=")[1]
                    $AccountType = $systemLocalUserWmic[($i + 1)]
                    $status = $systemLocalUserWmic[($i + 3)].split("=")[1]
                    $i = ($i + 4)  

                    "$name $domain $accounttype $status"

                }


                foreach ($v in $localWmicOut) {
                    $line = $v.Split(" ")
                    $typeTest = if ($line[2].split("=")[1] -eq "TRUE") { "Local" }
                    else { "Other account" } 
                    $v | Select-Object @{Label = "Name"; Expression = { $v.Split(" ")[0] } },
                    @{Label = "Domain"; Expression = { $line[1] } },
                    @{Label = "AccountType"; Expression = { $typeTest } },
                    @{Label = "Status"; Expression = { $line[3] } }
                }
            }
        }

        function systemLocalGroups {
            write-host "systemlocalgroups is running"
            #$PSversionG = ((Get-Host).Version).Major
            if ($systemPSversion -gt 2) {
                $LocalGroup = (Get-LocalGroup).Name
                $LocalGroup | ForEach-Object {
                    Get-LocalGroupMember -Group $_
                } 
            }
            else {
                wmic path win32_groupuser 
            }
        }

        function systemStartup {
            write-host "systemstartup is running"
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

        #used for json output
        function systemStartupJson {
            write-host "systemstartup is running"
            Get-Wmiobject Win32_startupcommand |  
            Select-Object Name, @{label = "command"; expression = { $_.Command } },
            @{label = "Location"; expression = { $_.Location } },
            @{label = "User"; expression = { $_.User } }

        }

        function systemInformation { 
            write-host "systemInformation is running"
            systeminfo | out-string
        }

        #used for json output
        function systemInformationJson {
            write-host "systemInformation is running"
            systeminfo -fo:csv
        }
        

        function systemNetstat { 
            write-host "systemNetstat is running"
            netstat -natob  
        }
 
        function systemProcess { 
            write-host "systemProcess is running"
            Get-WmiObject Win32_Process | Select-Object Name, ProcessId, ParentProcessId, CommandLine | Format-Table -AutoSize -Wrap  
        }

        #used for json output 
        function systemProcessJson {
            Get-WmiObject Win32_Process | Select-Object Name, ProcessId, ParentProcessId, CommandLine
        }
 
        function systemRoute { 
            write-host "systemRoute is running"
            route print  
        }
 
        function systemSessions { 
            write-host "systemSessions is running"
            net sessions  
        }
 
        function systemService {
            write-host "systemService is running"
            get-service | 
            where-object { $_.Status -eq "Running" } 
        }

        #for use with json output
        <#
        function systemServiceJson {
            write-host "systemService is running"
            get-service |
            #remove this line if require services that are not running
            where-object { $_.Status -eq "Running" } 
        } #>

        function systemPwhHistory {
            write-host "systemPwhHistory is running"
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
                    Get-Content $currentFilePath | Where-Object { $_.trim() -ne "" } 
        
                } 
            }
            #if there is just one file
            else {
                #set the file path
                $currentFilePath = $histPath + "\" + $histtxt
                #get the content from the file
                Get-Content $currentFilePath | Where-Object { $_.trim() -ne "" } 
            }

        }

        #for use with json output. Had to remove headings to get rid of blank lines
        function systemPwhHistoryJson {
            write-host "systemPwhHistory is running"
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
                    Get-Content $currentFilePath | Where-Object { $_.trim() -ne "" } 
        
                } 
            }
            #if there is just one file
            else {
                #set the file path
                $currentFilePath = $histPath + "\" + $histtxt
                #get the content from the file
                Get-Content $currentFilePath | Where-Object { $_.trim() -ne "" } 
            }

        }

 
        function systemTemp { 
            write-host "systemTemp is running"
            cmd /c "dir %TEMP% /b /s /a-d"  
        }
 
        function systemWinTemp { 
            write-host "systemWinTemp is running"
            cmd /c "dir C:\Windows\Temp /b /s /a-d"  
        }
 
        function systemLogicalDisk {
            write-host "systemLogicalDisk is running"

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
            Format-Table -AutoSize  
        }

        #used for json output. removed formatting to use properties
        function systemLogicalDiskJson {
            write-host "systemLogicalDisk is running"

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
            Select-Object DeviceID, $gbFreeSpace, $gbSize, FileSystem, VolumeName, $DriveType
        }

        function systemScheduledTasks {
            write-host "systemScheduledTasks is running"
            Get-ScheduledTask  |
            Select-Object -Property TaskName, State -ExpandProperty Actions |
            select-object @{label = "Task"; expression = { $_.TaskName } },
            @{label = "State"; expression = { $_.State } },
            @{label = "Execute file"; expression = { $_.Execute } } | 
            Sort-Object State | Format-Table -AutoSize  
        }

        #use for json output. remove the formatting to access properties
        function systemScheduledTasksJson {
            write-host "systemScheduledTasks is running"
            Get-ScheduledTask  |
            Select-Object -Property TaskName, State -ExpandProperty Actions |
            select-object @{label = "Task"; expression = { $_.TaskName } },
            @{label = "State"; expression = { $_.State } },
            @{label = "Execute file"; expression = { $_.Execute } } | 
            Sort-Object State
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
            $swCount = $switchOptions.Count
            "No systems were enumerated."
            "Please check for errors if results should be returned. The most common error is empty variable switchoptions"
            "The count of switchoptions is $swCount"
        }

        else {
            #"There are $resCount results."
            $results
        }

        $outputNDJson = export-ndjson
    }
    #The END block also runs once, after every item in the collection has been processes
    END {
        return $outputNDJson
    }
}

if ($loadingModule) {
    Export-ModuleMember -Function 'Get-System'
}