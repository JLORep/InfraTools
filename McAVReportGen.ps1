 <#
	.NOTES
	===========================================================================
	 Created on:   	12/06/2017 14:20
	 Created by:   	James Lockwood (jameseymail@hotmail.co.uk)
	 Organization: 	Net-Clarity.com
	 Filename:     	McAVReportGenerator
	===========================================================================
	.DESCRIPTION
		This script will query a list of machines ($Servers) for the various software versions of McAfee Antivirus, it will:
		o Import a list of Servernames (these are currently genrated outside of this script, i will add the function to establish the list in later releases 
		o Ping the Server
		o If successful, then a Function is passed to pull the MacAfee Registry Keys to establish Version
			o This info is passed to an array and appended to the McAVReport CSV
			o If Unsuccessful, then these "Uncontactable Machines" are passed to another Array & appened to the McAVReportNoPing CSV
		
		CSV currently returned Values: 
		
		HostName | DATVersion | DatDate
		
		This will take an hour to generate (over VPN) however when onsite (ventura.local LAN) it should take around 40 minutes
		
		CSV Target Values:
		
		Computername, DatVersion, DatDate, ProductVersion, EngineVersion, EngineVersionMinor, DatVersionMinor
		
	#>
 
 #Export/Import Location of ActiveWinServers.csv
 $ActivesLoc = "c:\scripts\final\output\ActiveWinServers.csv"
 
 #Export Location for Contactable Machine report (timestamping the filename)
 $ExportLocUP = 'C:\scripts\Final\output\McAVReport' + (get-date -format 'yyy-mm-dd-hhmm') + '.csv'
 
 #Export Location for Uncontactable Machine report (timestamping the filename)
 $ExportLocDOWN = 'C:\scripts\Final\output\McAVReportNoPing' + (get-date -format 'yyy-mm-dd-hhmm') + '.csv'

 #Creating empty arrays
 $winservers = @()
 $uncontactable = @()
 $servers = @()
 
 #Import Module
 Import-Module ActiveDirectory

 write-host 'Collecting & Filtering an Array of Computer Objects, only including ACTIVE Windows Servers....'

 #Get a list of servers in AD which are Windows Servers (all versions) & considered "Active"
 $winservers = Get-ADComputer -Filter {(OperatingSystem -like "*windows*server*") -and (Enabled -eq "True")} -Properties OperatingSystem | sort OperatingSystem | Select Name | export-csv $ActivesLoc -NoTypeInformation

  write-host 'Starting AV Scan...'
  
  $servers = import-csv -path $ActivesLoc
  
  write-host $servers

  Foreach ($Server in $Servers) {
  
function ping-host([string]$server) {
 #This function will perform a simple, small size single packet ping of a machine and return true/false for the result
  if ([string]::IsNullOrEmpty($server) ) {return $false}
  #ping first for reachability check
  $po = New-Object net.NetworkInformation.PingOptions
  $po.set_ttl(64)
  $po.set_dontfragment($true)
  [Byte[]] $pingbytes = (65,72,79,89)
  $ping = new-object Net.NetworkInformation.Ping
  $savedEA = $Erroractionpreference
  $ErrorActionPreference = 'silentlycontinue'
  $pingres = $ping.send($server, 1000, $pingbytes, $po)
  if (-not $?) {return $false}
  $ErrorActionPreference = $savedEA
  if ($pingres.status -eq 'Success') { return $true } else {return $false}
}
  #If $Server does not return a successful ping, export $Server(name) to CSV
if ((ping-host $server) -eq $false) {
 $uncontactable = New-Object PSobject -Property @{
  Computername = $server
  DATVersion = 'System Not Online' 
  Datdate = $null
  }
  
 #Append Hostname to outputcsv
		$uncontactable | export-csv -path $ExportLocDOWN -Append -NoTypeInformation
 
} else {

 try {
  #Set up the key that needs to be accessed and what registry tree it is under
  $key = 'Software\McAfee\AVEngine'
  $type = [Microsoft.Win32.RegistryHive]::LocalMachine

  #open up the registry on the remote machine and read out the TOE related registry values
  $regkey = [Microsoft.win32.registrykey]::OpenRemoteBaseKey($type,$server)
  $regkey = $regkey.opensubkey($key)
  $status = $regkey.getvalue('AVDatVersion')
  $datdate = $regkey.getvalue('AVDatDate')
 } catch {
  try {
   $key = 'Software\Wow6432Node\McAfee\AVEngine'
   $type = [Microsoft.Win32.RegistryHive]::LocalMachine
   #open up the registry on the remote machine and read out the TOE related registry values
   $regkey = [Microsoft.win32.registrykey]::OpenRemoteBaseKey($type,$server)
   $regkey = $regkey.opensubkey($key)
   $status = $regkey.getvalue('AVDatVersion')
   $datdate = $regkey.getvalue('AVDatDate')
  } catch {
   $status = 'Cannot read regkey'
  }
 }
 $Lineentry = New-Object PSobject -Property @{
  Computername = $server
  DATVersion = $status
  DatDate = $datdate
			
		} | select Computername, DatVersion, DatDate 
				  
				  
				
 }
 write-host $Lineentry 'AV Scan Completed! Exported to' $ExportLocUP 'AV Scan...'
	
	$Lineentry | export-csv -path $ExportLocUP -Append -NoTypeInformation
 
 }