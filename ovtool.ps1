# Configuration
$ovftool = "ovftool.exe"  # If the ovftool.exe is not in your path, you need to specify the full path here.
$sourceVM = 'ovftest'
$sourceVIServer = 'vCenter1.vmware.local'
$targetVIServer = 'vCenter2.vmware.local'
$targetDatacenter = 'Super Datacenter'
$sourceNetwork = 'VM Network'  # This is the portgroup that the VM is currently on.
$targetNetwork = 'VLAN188'  # This is the portgroup that you want the VM placed onto.
$targetCluster = 'Super Cluster'
$targetDatastore = 'VM_Template_Transfer'
 
# Connect to the source and destination vCenters.
Connect-VIServer $sourceVIServer
Connect-VIServer $targetVIServer
 
# Assign the vCenters in a lookup table to make things easy to access.
$VIServers = @{
  $DefaultVIServers[0].name = $DefaultVIServers[0];
  $DefaultVIServers[1].name = $DefaultVIServers[1]
}
 
# Get the moref of the source VM
$sourceVMMoref = (get-vm $sourceVM -Server $VIServers[$sourceVIServer]).extensiondata.moref.value
 
# Get a session ticket for the source and destination vCenter servers.  This is what allows us to specify a vCenter server as the source and destination with the ovftool.
echo "sourceVIServer = $($VIServers.$sourceVIServer)"
$sourceSession = Get-View -server $VIServers.$sourceVIServer -Id sessionmanager
$sourceTicket = $sourceSession .AcquireCloneTicket()
 
echo "targetVIServer = $($VIServers.$targetVIServer)"
$targetSession = Get-View -server $VIServers.$targetVIServer -Id sessionmanager
$targetTicket = $targetSession .AcquireCloneTicket()
 
# Build the parameters that will be used with the ovftool.
$sourceTicket = "--I:sourceSessionTicket=$($sourceTicket)"
$targetTicket = "--I:targetSessionTicket=$($targetTicket)"
$datastore = "--datastore=$($targetDatastore)"
$network = "--net:$($sourceNetwork)=$($targetNetwork)"
$source = "vi://$($sourceVIServer)?moref=vim.VirtualMachine:$($sourceVMMoref)"
$destination = "vi://$($targetVIServer)/$($targetDatacenter)/host/$($targetCluster)/"
 
# Display the command that will be ran.
echo $datastore $network $sourceTicket $targetTicket $source $destination
 
# Use PowerCLI to run the ovftool.  PowerCLI makes it easy to run commands with multiple parameters.  Sometimes this can be tricky to do with Windows.
& $ovftool $datastore $network $sourceTicket $targetTicket $source $destination