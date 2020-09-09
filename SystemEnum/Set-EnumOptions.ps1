function Set-EnumOptions {
    <#
	.SYNOPSIS
	This function will set which functions are run on the remote machine. 
     
	.DESCRIPTION
	A bit more description 

	.PARAMETER FromPipeline
	Shows how to process input from the pipeline, remaining parameters or by named parameter.

	.EXAMPLE
	Set-EnumOptions 'abc'

	Description of the example.

	#>

    begin {
        $includeOrExclude = $null
        [System.Collections.ArrayList]$switchOptions = @()
        $switchChoices = $null

        $testList = "1.  systemLocalUsers", 
        "2.  systemLocalGroups", 
        "3.  systemStartup",
        "4.  systemInformation", 
        "5.  systemNetstat", 
        "6.  systemProcesses", 
        "7.  systemRoute", 
        "8.  systemnUsers", 
        "9.  systemSessions", 
        "10. systemService", 
        "11. systemPwhHistory", 
        "12. systemTemp", 
        "13. systemWinTemp", 
        "14. systemLogicalDisk",
        "15. systemScheduledTasks"

        $allOptions = 
        foreach ($opt in $testList) {
            $opt.split(" ")[-1]
        }
    }

    process {
        "`n ######## SYSTEM ENUMERATION OPTIONS ######## `n"
        $testList
        "`n ####################################"
        "`n"

        function includeExcludeChoice {
            Read-host " I list options to include
 E list options to exclude
 A include all options
 Please select option"
        }

        function switchChoices {
            if ($includeOrExclude -eq "I") {
                $switchChoices = Read-host "Please choose the required information to include for system enumeration (eg 1,4,7)"
                $switchChoices
            }
            if ($includeOrExclude -eq "E") {
                $switchChoices = Read-host "Please choose the required information to exclude from system (eg 1,4,7)"
                $switchChoices
            }
        }        

        if ($null -eq $includeOrExclude) {
            $includeOrExclude = includeExcludeChoice
        }

        if ($includeOrExclude -eq "A") {
            #"include all is selected"
            foreach ($a in $allOptions) {
                $switchOptions.Add($a) > $null
            }
            return $switchOptions
        }

        if ($includeOrExclude -eq "I") {
            #"include is selected"
            $choices = switchChoices
            $choices = ($choices.trim(" ")).split(",")
            foreach ($choice in $choices) {
                $cIndex = $choice - 1
                $switchOptions.Add($allOptions[$cIndex]) > $null
            }
            return $switchOptions
        }
        elseif ($includeOrExclude -eq "E") {
            #"excluded is selected"
            $choices = switchChoices
            $choices = ($choices.trim(" ")).split(",")
            $allOptChoiceNums = 0..($allOptions.Length - 1) | foreach { $_ }
            $choices = (Compare-Object $allOptChoiceNums $choices).inputObject
            foreach ($choice in $choices) {
                $cIndex = $choice - 1
                $switchOptions.Add($allOptions[$cIndex]) > $null
            }
            return $switchOptions
        }

        else {
            "No valid option has been selected. Please select again."
            $includeOrExclude = includeExcludeChoice
        }
    }

    end {
        return $switchOptions
    }
}

if ($loadingModule) {
    Export-ModuleMember -Function 'Set-EnumOptions' 
}