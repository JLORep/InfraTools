<#
	.NOTES
	===========================================================================
	 Created on:   	26/07/2017 14:20
	 Created by:   	James Lockwood (jameseymail@hotmail.co.uk)
	 Organization: 	Net-Clarity.com
	 Filename:     	GenerateWinServersActiveWithinX.ps1
	===========================================================================
	.DESCRIPTION
		This script will:
		a) Prompt you for a timeframe (in whole days)
		b) Contact Active Directory, Identifying all Windows Server-Versioned Machine Objects, which have checked in within the specified timeframe
		b) This is then exported a CSV automatically
				
		****Note the lastlogontimestamp is only synchronised between DCs, the standard, every 14 days**** for most accurate results specify a DC or (array of DCs)
		
		CSV currently returned Values: HostName | LastLogonTimeStamp	
	#>

	
	#Setting up Variables
$daysinactive = Read-host 'How Many (Whole) Days Inactive??'
$domain = '*DOMAIN*' #Enter a DC name here if you require a "per DC" Report
$time = (Get-Date).Adddays(-($daysinactive)) 
$path = '\\****.local\data$\IT\Tech Services\MacafeeReports\ActiveServersArchive\' + (get-date -format 'yyy-MM-dd') + 'TimestampsNewerThan' + $daysinactive + 'Days.csv'

# Get AD computers from Active Directory, which are Windows Server and have the lastLogonTimestamp less than our time
$Servers = % {
Get-ADComputer -Filter {OperatingSystem -like '*windows*server*' -and LastLogonTimeStamp -gt $time} -Properties LastLogonTimeStamp} |
		
# Output hostname and lastLogonTimestamp into CSV
select-object Name,@{Name='Stamp'; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | 

export-csv -path $path -notypeinformation
