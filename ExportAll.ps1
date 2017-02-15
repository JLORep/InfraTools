######################################################
# Name: VMBackup to External Storage[ExportOnly.ps1] #
# Desc: Exports VM Clones to Filer                   #
######################################################
#                                                    #
# *Exports all VMs with a particular name as OVA	 #						
# *Use this to clean up any old BAK files            #
#                                                    #
######################################################
# Date: 29/05/2015                                   #
# Auth: jameseymail@hotmail.co.uk                    #
######################################################

#VM Name/String to search with - In this case all VM Names which end with -BAK will be exported as OVA
$VMString = *-BAK

#VCentre DNS Name
$VCDNS ="VC2.ad.mmu.ac.uk"

#Export Location
$ExportLoc = "\\ascfiler1\vm_repository\Dump"

#Create PS-Drive Mapping to the above
New-PSDrive -Name Y -PSProvider filesystem -Root $ExportLoc

#Clear Screen
clear-host

# Load PowerCLI Snapin & Print Header
Write-host "Loading PowerCLI" -ForeGroundColor Blue
$VMwareLoaded = $(Get-PSSnapin | ? {$_.Name -like "*VMware*"} ) -ne $null
If ($VMwareLoaded) { }
 Else
{
Add-PSSnapin -Name "VMware.VimAutomation.Core" | Out-Null
}

# Connect to CLI VCenter
Connect-VIserver -server $VCDNS

#Export VM(s) as OVA to Export Location
Get-VM -Name $VMString | Export-VApp -Destination $ExportLoc -Format Ova

