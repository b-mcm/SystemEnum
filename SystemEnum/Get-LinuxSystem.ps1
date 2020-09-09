function Get-LinuxSystem {
	<#
	.SYNOPSIS
	This function ...

	.DESCRIPTION
	A bit more description

	.PARAMETER ip
	A single list or array of ips 
	 
	.PARAMETER outFile
	The full path to save the results (e.g "C:\results.txt")

	.EXAMPLE
	Get-LinuxSystem -ip "10.10.10.5" -outFile "C:\results.txt"

	Call the function with the ip and the location to save results. 
	This may be used in an array of ips; 

	$fileNum = 1
	foreach ($ip in $ipArray) {
		#outfile would be changed for each iteration
		$outFile = "c:\outfile_"+$fileNum+"".txt"
		Get-LinuxSystem -ip $ip -outFile $outfile
		$fileNum++
	} 

	#>

	<# Enable -Confirm and -WhatIf. #>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		#run the command on the ip specified
		[string[]]$ip,
		[string]$outFile
	)

	begin {
		#run the following once
		
		#set the credentials
		$creds = Get-Credential
		#set the username
		$suser = $creds.UserName
		#set the password
		$sPassword = $creds.Password
		#clear the output
		$sReturn = $null
		#clear the sudo check
		$result = $null
		#list the commands to run on the remote system
		$CommandArray = 
		#run sudo commands on remote system
		"sudo -i",
		#shows all cu$rrent logins to system
		"who -a",
		#view the home directory of a user along with login time and idle time (may not exist on all systems)
		"finger",
		#if above doesn't work, gives similar information
		"pinky",	
		#displays the OS Name, Version and some other details about the current machine and the OS
		"uname -a",
		#view all network settings
		"ifconfig -a",
		#reads data from the wtmp log (login and logout events)
		"last",
		#information on last login of each user
		"lastlog",
		#shows current arp table
		"arp -an",
		#shows the ip routing table
		"route",
		#shows active internet connections (server and est) with user
		"netstat -tulanop",
		#shows active unix domain sockets (server and est)
		"netstat -pan",
		#shows the ip routing table
		#"netstat -rn",
		#shows current iptables firewall rules
		"iptables -L -n",
		#shows current data streams
		"lsof -i",
		#shows installed packages on system (may not work on all systems)
		"rpm -qi basesystem",
		#shows system uptime
		"uptime",
		#list all available services
		"chkconfig",
		#alternative to list available services (no pager means not run through less)
		"systemctl status --no-pager", 
		#list of all loaded systemd units (no pager options means not run through less)
		"systemctl --no-pager",
		#list units with host target
		"systemctl list-units --type=target --no-pager",
		#list all processes by user
		"ps -aux",
		#processes with a full listing
		"ps -alef",
		# list open files that are not linked
		"lsof +L1",
		# environmental variables
		"env",
		#sudo information for current user
		"sudo -l",
		#outputs the current working directory path
		"pwd",
		#lists all the files and their permissions (Including Hidden Files) in the current directory
		"ls -al",
		#Lists out all the SUID and SGID files
		"find / -perm /6000;",
		#list all the users on the system
		"cat /etc/passwd",
		#list all the groups on the system
		"cat /etc/group",
		#display all the users and their password hashes
		"cat /etc/shadow",
		#display the current user and group IDs
		"id",
		#show all services with status
		"service --status-all"
	}
	#this is where the main function is
	process {
		#create the ssh session with the given ip and credentials for the remote system
		$oSessionSSH = New-SSHSession -ComputerName $ip -Credential $creds

		#start the remote stream to issue and read commands. 
		$stream = $oSessionSSH.Session.CreateShellStream("get-enum", 0, 0, 0, 0, 1000)
		#run this so sudo commands can be run on the remote system. If expecting a password in remote command, the password is entered
		$result = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for $($sUser):" -SecureAction $sPassword
		if ($result -eq "False") {
			#enters the password
			$result = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password di $($sUser):" -SecureAction $sPassword
		}
		#set the counter for progress bar
		$i = 1
		#for each command    
		foreach ($command in $commandArray) {
			#show the progress and the command runmning
			Write-Progress -Activity "Command [$($command)]" -Status "Command $i of $($commandArray.Count)" -PercentComplete (($i / $commandArray.Count) * 100) 
			#read the stream
			$sReturn = $stream.Read()
			#write the current command to the console
			$stream.WriteLine($command)
			#wait for command to execute
			Start-Sleep -s 2
			#save the output of the command in the stream to the variable
			$sReturn = $sReturn += $stream.Read()
		}
	}
	#run at the end
	end {
		
		$sreturn | Out-File "C:\linux2.txt" -Encoding utf8
		Write-host "Linux system enum for ip [$ip] is complete" -ForegroundColor Green
		Wtite-host "Results have been saved to $outFile"


		(Get-SSHSession).SessionId | ForEach-Object { Remove-SSHSession -SessionId $_ }
	}
}

if ($loadingModule) {
	Export-ModuleMember -Function 'Get-LinuxSystem'
}