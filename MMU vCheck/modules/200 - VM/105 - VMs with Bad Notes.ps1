# vms with no notes, or bad notes
function fun_vm_notes{
param($arr_vm_list)

    $arr_local = @()
    $arr_vm_list_local = $arr_vm_list | Where-Object {!$_.Notes -or $_.Notes -eq "Windows 2012 R2 Gold Build - Export from VC2 to Auron"}

    foreach($vm in $arr_vm_list_local){
     
        $obj_local = New-Object –TypeName PSObject    
        $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $vm.Name
        $obj_local | Add-Member –MemberType NoteProperty –Name Notes –Value $vm.Notes


        if($vm.name -like "LB-*" -or $vm.name -like "NSX-*"){}
        else{$arr_local += $obj_local}

      }

    $arr_local

}