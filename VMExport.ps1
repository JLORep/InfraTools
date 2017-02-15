#===============================#
# Export VM to External Storage #
#       Version 1.0             #
#      James Lockwood           #
#        19/05/2015             #
#===============================#

Add-PSSnapin -Name "VMware.VimAutomation.Core"
$vm = "Bobby-19052015-104216-BAK"
Connect-VIserver -server VC2.ad.mmu.ac.uk
#$datastore = Get-Datastore "Prod_windows04"
#$myVApp = get-VApp -Name $datastore = Get-Datastore "Prod_windows04"
Get-VM -Name $vm | Export-VApp -Format OVA -Destination "\\ascfiler1\vm_repository\CloneTest"
