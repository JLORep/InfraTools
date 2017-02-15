#***************************************************************************
#
# Add NFS Storage to All Hosts of a chosen cluster.
# Author: Brad Payne
# Date: 04/05/11
#
#***************************************************************************
if ((Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null)
{
	Add-PSSnapin VMware.VimAutomation.Core
}
&"C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"

$vCenter = Read-Host "Enter vCenter Name or IP"
Connect-VIServer $vCenter

$clusters = @(Get-Cluster)
if ($clusters.count -gt 1)
{
	
	for ($clusterCount = 0; $clusterCount -lt $clusters.count; $clusterCount++)
	{
		$optionvalue = $clusterCount + 1
		Write-Host $optionvalue ")" $clusters[$clusterCount].Name
		
	}
	$input = Read-Host "Select a Cluster"
	$selectedCluster = $clusters[$input - 1]
}
else
{
	$selectedCluster = $clusters[0]
	
}

$ClusterName = $selectedCluster.Name

$Hosts = @(Get-Cluster -Name $ClusterName | Get-VMHost)
Write-Host $Hosts

$NewNFSHost = Read-Host "Enter NFS Host IP"
$NewExportPath = Read-Host "Enter Export Path"
$NewDataStore = Read-Host "Enter name for new DataStore"

#Get-Cluster -Name $ClusterName | Get-VMHost | New-Datastore -Nfs -Name $NewDataStore -Path $NewExportPath -NfsHost $NewNFSHost

for ($esxcounter = 0; $esxcounter -lt $Hosts.Count; $esxcounter++)
{
	$dsExists = Get-VMHost $Hosts[$esxcounter].name | Get-Datastore $NewDataStore
	if ($dsExists -eq $null)
	{
		New-Datastore -Nfs -VMHost $Hosts[$esxcounter].name -Name $NewDataStore -Path $NewExportPath -NfsHost $NewNFSHost
	}
	else
	{
		Write-Host -ForegroundColor Red "Datastore already exists on" $Hosts[$esxcounter].name
	}
}