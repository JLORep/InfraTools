# vms with virtual scsi bus sharing mode
function fun_vm_bus_sharing_mode{
param($arr_vm_list)

    $arr_local = @()
    $arr_vm_list_local = $arr_vm_list 
    
    foreach($vm in $arr_vm_list_local){
        
        $buses = $vm | Get-ScsiController | Where-Object {$_.BussharingMode -eq "Virtual"}

        foreach($bus in $buses){
     

        
            $obj_local = New-Object –TypeName PSObject    
            $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $vm.Name
            $obj_local | Add-Member –MemberType NoteProperty –Name BussharingMode –Value $bus.BussharingMode
        
            $arr_local += $obj_local

          }
      }

    $arr_local

}