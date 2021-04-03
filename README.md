# SystemEnum
Functions to enumerate windows and linux system. Written in powershell. Outputs as either a txt document, or ndjson for the windows enumeration

### Get-LinuxSystem
Get-LinuxSystem is used to enumerate a remote linux system. 

* It is required that the remote system allows ssh, and that you know the credentials.
* The powershell module Posh-SSH is required

> Install-Module -Name Posh-SSH

### Export-NDjson.ps1
Export-NDjson is used to gather the information of a windows system, and output in the ndjson format.

### Set-Trustedhost.ps1
Set-Trustedhost takes a sinlge or list of ips, and adds it to the trusted host file. This is required for remote access to a system.

*You should revert this list once you have completed your system enumeration*

### Set-EnumOptions.ps1
Set-EnumOptions is a user prompted script. Use this to choose which options are run for the system enumeration. 
This only outputs the options to the screen, the results need to be stored in a variable for use. 

### Get-System.ps1
Get-System is used to enumerate the system, with the given ip(s) and the given options. This can be a local or remote system.

## Set up
Run the scripts from the same folder, as you will use them to make variables. 
1. Download the scripts (ps1) files to the same directory 
2. Run the scripts to load the functions. This requires elevated privileges for some parts of the scripts

* The scripts can be used for either a local or remote machines, for a single or multiple.
* For running against a remote machine, WINRM will or psremote will need to be enabled.
* For the linux system enum, the module Posh-SSH is required

## Running for a single local (windows) system

1. Set the variable for the ip
> $ip = "1.1.1.1"
2. Set the options for which information you require
> $switchOptions = set-enum
3. Run the function (storing as a variable recommended)
> $sysEnum = Get-System -ip $ip -switchOptions $switchoptions
4. Output to a file (ensure you have write access where the outfile is going to be saved)
> $sysEnum | out-file "C:\Users\User\Documents\sysenum.txt"

## Running for multiple (windows) systems

1. Set a list of ips
> $ip = "1.1.1.1","2.2.2.2"
2. Set the options for the information you require
> $switchOptions = set-enum
3. Set the trusted hosts file values
> Set-Trustedhost $ip
  *ensure that the output shows that your ips are in the trusted hosts
*We are going to run an invoke command, so the credentials must also be supplied*. For multiple ips, the credentials must be the same*
4. Set the credentials for the remote machine
> $creds = set-credential
5. Run the function (foreach is used so the $ip can be passed to the function, used in headings within the function)
> $systemResults = 
> foreach $computer in $ip {
>   invoke-command -computername $ip -credential $creds -authentication negotiate -scriptblock ${function:Get-System} -argumentlist $ip,$switchOptions
> }
6. Output the results
> $systemResults | out-file "C:\Users\User\Documents\sysenum.txt"

## Running for a single linux system

1. Set the ip
> $ip = "1.1.1.1"
2. Set the path of the output file
> $outfile = "C:\linuxResultsFile.txt"
3. Run the function with the ip and output file parameters
> Get-LinuxSystem -ip $ip -outfile $outfile

## Running for ndjson output

Currently, this outputs as ndjson. Originally for ingestion in the ELK stack, this will probably be changed to output json.
Json output would allow ingestion from a directory, making use of the elastic or logstash capabilies

**This is almost the same functionality as get-system. This just outputs the results as ndjson format, and does not allow choosing of options.** 

1. Set the ip variable
> $ip = "1.1.1.1"
2. Run the function, and output to a file. the nonewline options ensures there is not a line on the end of the file. 
> Export-ndjson -ip $ip | out-file "c:\ndjsonOutput.ndjson -nonewline"