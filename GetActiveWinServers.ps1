#Queries Active Directories Computer Objects for a list of all Windows Servers versioned servers, which have checked into ActiveDirectory within the past x days

#Import Module
Import-Module ActiveDirectory

#where to store a list of active Windows Servers
$ExportLocWin = 'C:\scripts\Final\ActiveWinServers.csv'

write-host 'Contacting VENTURAUK | Collecting & Filtering Array of Computer Objects | Only including Windows Servers that AD considers Active....'

# Get a list of servers in AD which are Windows Servers (all versions) & Active
$winservers = Get-ADComputer -Filter {(OperatingSystem -like "*windows*server*") -and (Enabled -eq "True")} -Properties OperatingSystem | sort OperatingSystem | Select Name | export-csv $ExportLocWin -NoTypeInformation

write-host 'Sucessfully Exported as CSV to:' $ExportLocWin