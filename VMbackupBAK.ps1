####################################################################
# Name: VMBackup                                                   #
# Desc: Backups a specific VM cloning it from a previous Snapshot  #
# Date: 05/07/2010                                                 #
# Auth: mail.al.virtu@gmail.com                                    #
# Revision 1 - James Lockwood - 20/05/2015                         #
####################################################################

#VCentre DNS Name
$VCDNS ="VC2.ad.mmu.ac.uk"

#Export Location
$ExportLoc = "\\ascfiler1\vm_repository\CloneTest\AutoExport"

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

#Import CSV of VMs to be backed up
$FullVMList = Import-CSV C:\scripts\mybackups.csv

#Datastore to put backups
$TargetDS = "backup_vmstore01"

#Performing Snapshot-Clone-Rename-Copy & Delete
Foreach($machine in $FullVMList){

#Recurse through CSV to obtain SourceVM Variable
$SourceVM = Get-VM $machine.MasterVM

# Backup Folder to keep your Backups
$BACKUP_FOLDER = "Backup"

# vCenter Server
$vCenterServer="vc2.ad.mmu.ac.uk"

# Set Date format for clone names
$CloneDate = Get-Date -Format "ddMMyyyy-hhmmss"

# Check VM Parameter if no VM is specified then the script ends here.
If (($SourceVM -eq $Null ) -or ($TargetDS -eq $Null)) {
Write-Host "Usage: "
Write-Host "BackupVM: " -ForeGroundColor White
Exit }

# Functions to check whether a VM or DS Exists
function ExistVM([string] $VMName) {
Get-VM | Foreach-Object { $FullVMList += $_.Name }

if ( $FullVMList.Contains( $VMName ) ) {
$true
} else {
$false
}
}

function ExistDS([string] $DSName) {
Get-DataStore | Foreach-Object { $FullDSList += $_.Name }

if ( $FullDSList.Contains( $DSName ) ) {
$true
} else {
$false
}
}

# PowerCLI Header
Write-host "Loading PowerCLI" -ForeGroundColor Red
$VMwareLoaded = $(Get-PSSnapin | ? {$_.Name -like "*VMware*"} ) -ne $null
If ($VMwareLoaded) { }
Else
{
Add-PSSnapin -Name "VMware.VimAutomation.Core" | Out-Null
}

# Connect vCenter Server
Write-host "Connecting vCenter" -ForeGroundColor Yellow
Connect-VIserver -server $vCenterServer | Out-Null

# Let’s Rock
if ( ExistVM( $SourceVM ) -and ExistDS( $TargetDS ) ) 
{

$VM = Get-VM $SourceVM

Write-Host -foregroundcolor Green " + Creating SnapShot " $SourceVM

$CloneSnap = $VM | New-SnapShot -Name "$CloneDate-$SourceVM-CloneSnapShot"
$VMView = $VM | Get-View
$CloneFolder=$VMView.Parent
$CloneSpec=New-Object Vmware.Vim.VirtualMachineCloneSpec
$CloneSpec.SnapShot=$VMView.SnapShot.CurrentSnapShot
$CloneSpec.Location=New-Object Vmware.Vim.VirtualMachineRelocateSpec
$CloneSpec.Location.Datastore=$(Get-Datastore -Name $TargetDS | Get-View).MoRef
$CloneSpec.Location.Transform=[Vmware.Vim.VirtualMachineRelocateTransformation]::Sparse
$CloneName = "$VM-$CloneDate-BAK"

Write-Host -foregroundcolor Green " + Cloning " $SourceVM "into" $CloneName

$VMView.CloneVM($CloneFolder,$CloneName,$CloneSpec) | Out-Null

Write-Host -foregroundcolor Green " + Moving to Folder " $BACKUP_FOLDER

Move-VM $CloneName -Destination $BACKUP_FOLDER | Out-Null

#Export as OVA File
Write-host "Exporting as OVA File" -ForeGroundColor Yellow
Write-host "(This will NOT overwrite any previous OVA Backups)" -ForeGroundColor Yellow
Get-VM -Name $CloneName | Export-VApp -Format OVA -Destination $ExportLoc



Get-VM $CloneName | Out-Null
Write-Host -foregroundcolor Green " + Deleting SnapShot .. "
Get-Snapshot -VM $( Get-VM -Name $VM ) -Name $CloneSnap | Remove-Snapshot -confirm:$false

if ( ExistVM( $CloneName ) ) {

Write-Host -ForegroundColor Green " + $SourceVM has been Cloned into $CloneName "
} else {

Write-Host -foregroundcolor Red " + ERROR: $SourceVM could not be Backed Up!"
}
} else {
Write-Host -foregroundcolor Red " + ERROR: Either VirtualMachine ($VM2Backup) or DataStore ($TargetDS) does not exist!"

}
}

#Disconnect from vCentre
Write-host "Closing vCenter session " -ForeGroundColor Yellow
Disconnect-VIServer -Confirm:$false