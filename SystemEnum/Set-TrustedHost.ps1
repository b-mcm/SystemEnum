function Set-TrustedHost {
	<#
	.SYNOPSIS
	This function checks the trusted hosts file for current values. 
	It then takes a list of ips, and checks if these are in the current
	trusted hosts.  
	If the ips are not in the trusted hosts, the ips are added to the trusted
	hosts list.

	.DESCRIPTION
	This function checks the trusted hosts file for current values. 
	It then takes a list of ips ($ipList), and checks if these are in the current
	trusted hosts. 
	If the ips are not in the trusted hosts, the ips are added to the trusted
	hosts list.

	.PARAMETER ipList
	ipList is a list of ips. Can be a string or list, as shown below.
	$ipList = "10.10.10.1","10.10.10.2"
	$ipList = gc "iplist.txt"

	.EXAMPLE
	Set-TrustedHost -ipList $ipList

	Run the function after defining the ipList parameter.

	Set-TrustedHost -ipList "10.10.10.2","10.10.10.1"

	Run the function defining the ips 

	#>
	param (
		[string[]]$ipList
	)

	#get the current list of trusted hosts
	$currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).value
	#set an empty array for ip values we need to add to trusted hosts file
	[System.Collections.ArrayList]$newList = @()

	#check if ips are in trusted host file
	foreach ($ip in $ipList){
		#if the ip is not in the trusted host list
		if($currentTrustedHosts -notcontains $ip) {
			#add the ip to a list
			$newList.add($ip) > $null
		}
	}
	#check if there are ips to be added to the trusted host list
	if ($null -ne $newList) {
		#change the array to a string accepted by wsman
		$newValues = $newList -join ","
		#add the ips to the current list of trusted hosts without a prompt
		Set-Item WSMan:\localhost\Client\TrustedHosts -Value $newValues -Concatenate -Force
	}
	#show the current values of trusted hosts
	$updatedVal = (Get-Item WSMan:\localhost\Client\TrustedHosts).value
	"The current values of the trusted host file is $updatedVal"
}

#set the list of ips
#$ipList = "192.168.159.129"
#or set the list of ips
#$ipList = gc "d:\ips.txt"
#run the function
#Set-TrustedHost -iplist $ipList

if ($loadingModule) {
	Export-ModuleMember -Function 'Set-TrustedHost'
}