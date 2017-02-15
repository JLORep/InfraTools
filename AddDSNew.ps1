<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.98
	 Created on:   	27/11/2015 14:20
	 Created by:   	Jamesey
	 Organization: 	NetClarity
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
# User variables: adjusted for the environment
###################################
# Load VMWare add-ins
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{
	Add-PSSnapin VMware.VimAutomation.Core
}

# Set location of credentials file
$credsFile = "C:\Scripts\creds.crd"
# import credentials file
$Creds = Get-VICredentialStoreItem -file $credsFile
# Datacenter name
$datacenterName = "ITS"
# NFS Host IP
$nfsHost = "10.112.250.2"
# NFS share name
$nfsShare = "\vol\VMBackups"
# New datastore name
$nfsDatastore = "VMBackups"

####################################################################################################################
# Start Of Execution
####################################################################################################################

#connect to vCenter using credentails supplied in credentials file
Connect-VIServer -Server $Creds.Host -User $Creds.User -Password $Creds.Password -WarningAction SilentlyContinue | Out-Null
echo "Connected to vCenter"

echo "starting addition of NFS share to ESXi Hosts"

foreach ($esx in get-datacenter -Name $datacenterName | get-VMhost | sort Name)
{
	$esx | New-Datastore -Nfs -Name $nfsDatastore -NFSHost $nfsHost -Path $nfsShare
	echo "NFS share added to $esx"
}

echo "Task completed"

Disconnect-VIServer -Server $Creds.Host -Force -Confirm:$False