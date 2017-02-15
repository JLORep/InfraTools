# Import Backup CSV
$backupinfo =  Import-Csv C:\scripts\mybackups.csv
 
#Set Date format for clone names
$date = Get-Date -Format "yyyyMMdd"
 
#Set Date format for emails
$time = (Get-Date -f "HH:MM")
 
#Connect to vCenter
Connect-VIServer "vc2.ad.mmu.ac.uk"
 
foreach ($customer in $backupinfo)
{
    $vm = Get-VM $customer.MasterVM
     
    #Send Start Email
    C:\scripts\backupstartedemail.ps1
     
    # Create new snapshot for clone
    #$cloneSnap = $vm | New-Snapshot -Name "Clone Snapshot"
     
    # Get managed object view
    #$vmView = $vm | Get-View
     
    # Get folder managed object reference
    #$cloneFolder = $vmView.parent
     
    # Build clone specification
    #$cloneSpec = new-object Vmware.Vim.VirtualMachineCloneSpec
    #$cloneSpec.Snapshot = $vmView.Snapshot.CurrentSnapshot
 
    # Make linked disk specification
    #$cloneSpec.Location = new-object Vmware.Vim.VirtualMachineRelocateSpec
    #$cloneSpec.Location.Datastore = (Get-Datastore -Name $customer.BackupDS | Get-View).MoRef
    #$cloneSpec.Location.Transform =  [Vmware.Vim.VirtualMachineRelocateTransformation]::sparse
 
    #$cloneName = "$vm-$date"
 
    # Create clone
    #$vmView.CloneVM( $cloneFolder, $cloneName, $cloneSpec )
 
    # Write newly created VM to stdout as confirmation
    #Get-VM $cloneName
 
    # Remove Snapshot created for clone
    #Get-Snapshot -VM (Get-VM -Name $customer.MasterVM) -Name $cloneSnap | Remove-Snapshot -confirm:$False
     
    #Send Complete Email
    C:\scripts\backupcompletedemail.ps1
}
#Disconnect from vCentre
Disconnect-VIServer -Confirm:$false
