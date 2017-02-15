<#

.SYNOPSIS
This is a Powershell script to find all services running with a non-starndard account

.DESCRIPTION
The script query a list of computers (provided by a text file) for all 
services, filtering out any services that are using the standard accounts: 
"LocalSystem","NT AUTHORITY\NetworkService" and "NT AUTHORITY\LocalService"
The services are not required to be running to be processed by this script.
Once the results have been processed the output will be converted to a 
HTML document and launched in your default browser when completed

.EXAMPLE
./FindNonStandardServiceAccounts.ps1

.NOTES
This script was created by Brad Call of Internal I.T. Limited
bradcall@internalit.ca
www.internalit.ca
@Internal_IT

#>

#Sets the location for the report
$Report= "c:\TEMP\Audit_Report.html"

# Enter path to and name for text file containing the computer list
$ComputerList= Read-Host "Enter full path to txt file (c:\comps.txt)"

# Read the text file and enters the conten into a variable
$Computers= Get-Content $ComputerList

# Set the html formatting for the report
$HTML=@"
<title>Non-Standard Service Accounts</title>
<style>
BODY{background-color :#FFFFF}
TABLE{Border-width:thin;border-style: solid;border-color:Black;border-collapse: collapse;}
TH{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color: ThreeDShadow}
TD{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color: Transparent}
</style>
"@

# Processes each computer in the list
ForEach ($Computer in $Computers)
{
# Query the each computer its services
Get-WmiObject -ComputerName $Computer -class Win32_Service -ErrorAction SilentlyContinue | 

# Filters out the standard service accounts
Where-Object -FilterScript {$_.StartName -ne "LocalSystem"}|
Where-Object -FilterScript {$_.StartName -ne "NT AUTHORITY\NetworkService"} | 
Where-Object -FilterScript {$_.StartName -ne "NT AUTHORITY\LocalService"} |

# Selects conten to display in the report
Select-Object -Property StartName,Name,DisplayName|

# Converts the output to html format and writes it to a file
ConvertTo-Html -Property StartName,Name,DisplayName -head $HTML -body "<H2>Non-Standard Service Accounts on $Computer</H2>"| Out-File $Report -Append
}
#Launches the report for viewing
Invoke-Item $Report