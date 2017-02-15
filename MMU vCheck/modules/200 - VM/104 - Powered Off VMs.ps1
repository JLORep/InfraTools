# powered off VMs
function fun_vm_powered_off{
param($arr_vm_list)

    $arr_local = @()
    $arr_vm_list_local = $arr_vm_list | Where-Object {$_.Runtime.PowerState -ne "poweredOn"}

    foreach($vm in $arr_vm_list_local){
     

     $local_notes = Get-VM $vm.Name
        
        $obj_local = New-Object –TypeName PSObject    
        $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $vm.Name
        $obj_local | Add-Member –MemberType NoteProperty –Name SwappedMemoryMB –Value $vm.Runtime.PowerState
        $obj_local | Add-Member –MemberType NoteProperty –Name BootTime –Value $vm.Runtime.BootTime
        $obj_local | Add-Member –MemberType NoteProperty –Name Notes –Value $local_notes.Notes
        
        $arr_local += $obj_local

      }

    $arr_local

}