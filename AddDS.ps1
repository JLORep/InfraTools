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
# NFS Host IP
$nfsHost = "filer2.ad.mmu.ac.uk"
# NFS share name
$nfsShare = "\vol\VMBackups"
# New datastore name
$nfsDatastore = "VMBackups"


####################################################################################################################
# Start Of Execution
####################################################################################################################


#connect to vCenter using credentials supplied in credentials file
Connect-VIServer -Server $Creds.Host -User $Creds.User -Password $Creds.Password -WarningAction SilentlyContinue | Out-Null
echo "Connected to vCenter"


echo "starting addition of NFS share to ESXi Hosts"

Import-Csv "C:\Scripts\datacenters.csv" -UseCulture | %{
	foreach ($esx in (Get-Datacenter -Name $_.dcName | Get-VMhost | Sort Name))
	{
		$esx | New-Datastore -Nfs -Name $nfsDatastore -NFSHost $nfsHost -Path $nfsShare
		echo "NFS share added to $esx"
	}
}

echo "Task completed"


#Disconnect-VIServer -Server $Creds.Host -Force -Confirm:$False
