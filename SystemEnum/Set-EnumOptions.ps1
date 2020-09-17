function Set-EnumOptions {
    <#
	.SYNOPSIS
	This function will set which functions are run on the remote machine. 
     
	.DESCRIPTION
	This is a menu function. It will take user selections, to create an output of the
    functions to run for the Get-System function. 

	#PARAMETER FromPipeline
	Shows how to process input from the pipeline, remaining parameters or by named parameter.

	.EXAMPLE
	Set-EnumOptions

	No parameters. Input numbers, separated by a comma. No spaces are required. Choose to either include
    chosen options, exclude chosen options, or include all options. 

	#>

    begin {
        #set the options to be empty
        $includeOrExclude = $null
        #set the output to be empty
        [System.Collections.ArrayList]$switchOptions = @()
        #set the built options to be empty
        $switchChoices = $null
        #load the list of options
        $allOptions = 
        "systemLocalUser", 
        "systemLocalGroups", 
        "systemStartup",
        "systemInformation", 
        "systemNetstat", 
        "systemProcesses", 
        "systemRoute",
        "systemSessions", 
        "systemService", 
        "systemPwhHistory", 
        "systemTemp", 
        "systemWinTemp", 
        "systemLogicalDisk",
        "systemScheduledTasks"
        #create the menu items from the current list of functions (start at list number 1)
        $listNum = 1        
        [System.Collections.ArrayList]$testList = @()
        foreach ($opt in $allOptions) {
            [void]$testList.Add("$listNum. $opt")
            $listNum++
        }
    }
    #display the menu
    process {
        Write-host "`n ######## SYSTEM ENUMERATION OPTIONS ######## `n"
        foreach ($opt in $testList) {
            Write-host $opt
        }
        write-host "`n ####################################"
        Write-host "`n"
        #Ask user if chosen options will be included or excluded in system enumeration
        function includeExcludeChoice {
            #The user chosen options will be included in the output,
            #excluded in the output, or all will be included in the output
            Read-host " I list options to include
            E list options to exclude
 A include all options
 Please select option"
        }
        #build the list of index values from user choices
        function switchChoices {
            if ($includeOrExclude -eq "I") {
                #input which options are to be included
                $switchChoices = Read-host "Please choose the required information to include for system enumeration (eg 1,4,7)"
                #Return the choices
                $switchChoices
            }
            #Exclude options in the output
            if ($includeOrExclude -eq "E") {
                #Input which options are to be excluded
                $switchChoices = Read-host "Please choose the required information to exclude from system (eg 1,4,7)"
                #Return the choices
                $switchChoices
            }
        }        
        #if the user has not run the first menu option yet to choose include, exclude or all
        if ($null -eq $includeOrExclude) {
            #run the menu for user to choose include, exclude or all 
            $includeOrExclude = includeExcludeChoice
        }
        #Choice include all options
        if ($includeOrExclude -eq "A") {
            #"include all is selected"
            #For each of the options in the full list
            foreach ($a in $allOptions) {
                #add to the output list
                [void]$switchOptions.Add($a)
            }
            #return the final list of function names to be run
            return $switchOptions
        }
        #Include is selectd
        if ($includeOrExclude -eq "I") {
            #"include is selected"
            #store the chosen meanu values in a variable
            $choices = switchChoices
            #User input is stored as single string line.
            #Remove spaces, and split each choice by the comma to
            #change from single string to list of values
            $choices = ($choices.trim(" ")).split(",")
            #for each of the values in the the created choice list
            foreach ($choice in $choices) {
                #Minus 1 from the value, as array index begins at 0
                $cIndex = $choice - 1
                #Add the option using the array index to a new array
                [void]$switchOptions.Add($allOptions[$cIndex])
            }
            #Return the final array with all the options the user has listed
            return $switchOptions
        }
        #The user has chosen to exclude selected options
        elseif ($includeOrExclude -eq "E") {
            #"excluded is selected"
            #Add the user selected values to a variable. User input is stored as a single line of string type
            $choices = switchChoices
            #Take the string, remove the spaces. Split by the comma, to create a list of values instead of single 
            #line string line. 
            $choices = ($choices.trim(" ")).split(",")
            #create a temporary list of all possible choice (index) values.
            #This will be the list of index values. Minus 1, index starts at 0.
            $allOptChoiceNums = 0..($allOptions.Length - 1) | ForEach-Object { $_ }
            #Compare the full list to the user options. Only return values from the full list that are not in the 
            #user choices. Output of compare is a table, only want the values of inputObject property and no header 
            $choices = (Compare-Object $allOptChoiceNums $choices).inputObject
            #for each of the choices in the created list
            foreach ($choice in $choices) {
                #Minus 1 from the values, as index starts counting at 0
                $cIndex = $choice - 1
                #Add each option using the given index values
                [void]$switchOptions.Add($allOptions[$cIndex])
            }
            #return the completed array with functions to run
            return $switchOptions
        }
        #No valid option (I, E, or A) has been chosen
        else {
            #Inform user no valid option chosen
            "No valid option has been selected. Please select again."
            #Run the menu again for user input
            $includeOrExclude = includeExcludeChoice
        }
    }

    end {
        #Return the array of switch options. This is a list of functions, that will be used in
        #Get-System switch section. 
        
    }
}
#Load the module, so command is available in powershell. Can be commented out if you do not wish to import 
#module to powershell. You will have to reference the file using path, or copy paste the function. 
if ($loadingModule) {
    Export-ModuleMember -Function 'Set-EnumOptions' 
}