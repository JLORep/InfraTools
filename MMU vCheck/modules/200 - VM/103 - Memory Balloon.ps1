# get any VM that has any value of ballooned memory or swapped memory over 100MB
function fun_vm_memory_balloon{
param($arr_vm_list)

    $arr_local = @()
    $arr_vm_list_local = $arr_vm_list | Where-Object {$_.Summary.QuickStats.BalloonedMemory -gt "0" -or $_.Summary.QuickStats.SwappedMemory -gt "400"}

    foreach($vm in $arr_vm_list_local){
     
        $obj_local = New-Object –TypeName PSObject    
        $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $vm.Name
        $obj_local | Add-Member –MemberType NoteProperty –Name SwappedMemoryMB –Value $vm.Summary.QuickStats.SwappedMemory
        $obj_local | Add-Member –MemberType NoteProperty –Name BalloonedMemoryMB –Value $vm.Summary.QuickStats.BalloonedMemory
        $arr_local += $obj_local

      }

    $arr_local

}
