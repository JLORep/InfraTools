# get any VM that has snapshots older than x days and find the user that took it
function fun_vm_consolodation{
param($arr_vm_list)
    $arr_local = @()
    $local_consolodation = $arr_vm_list | where {$_.ExtensionData.Runtime.consolidationNeeded}
    foreach ($local_vm in $local_consolodation)
    {      
        
        # add to an object
        $obj_local = New-Object –TypeName PSObject    
        $obj_local | Add-Member –MemberType NoteProperty –Name VM –Value $local_vm.name
        $obj_local | Add-Member –MemberType NoteProperty –Name Notes –Value $local_vm.notes

        # add object to an array
        $arr_local += $obj_local

        
    }
    $arr_local
}