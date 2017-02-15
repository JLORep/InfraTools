# list the state of the hosts
function fun_host_state{
param($var_cluster)
    
    $arr_host_list = $var_cluster | Get-VMHost

    $arr_host_state = @()

    foreach ($vm_host in $arr_host_list){
        
        $obj_local = New-Object –TypeName PSObject    
        $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $vm_host.Name
        $obj_local | Add-Member –MemberType NoteProperty –Name ConnectionState –Value $vm_host.ConnectionState
        $obj_local | Add-Member –MemberType NoteProperty –Name PowerState –Value $vm_host.PowerState
        $arr_host_state += $obj_local

    
    }
    

    $arr_host_state

}