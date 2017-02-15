# check cluster CPU Level - Green if below 200% Red if abover 200%
# check cluster Memory Level - Green if below 50% Red if abover 50%

function fun_cluster_health{
param($var_cluster)
    
    $arr_host_list = $var_cluster | Get-VMHost
    $var_vm_cpu_count = 0

    $local_vm_list = $var_cluster | Get-VM

    foreach ($local_vm in $local_vm_list){
        $var_vm_cpu_count += $local_vm.NumCpu
    }
    
    [int]$var_host_cpu = 0
    [int]$var_host_cpu_total = 0
    [int]$var_host_memory = 0
    [int]$var_host_memory_total = 0
    [int]$var_host_cpu_count = 0
    $var_drs_enabled = $var_cluster.DrsEnabled
    $var_drs_automation_level = $var_cluster.DrsAutomationLevel

    foreach ($vm_host in $arr_host_list){
        
        $var_host_cpu = $var_host_cpu + $vm_host.CpuUsageMhz
        $var_host_cpu_total = $var_host_cpu_total + $vm_host.CpuTotalMhz
        $var_host_memory = $var_host_memory + $vm_host.MemoryUsageGB
        $var_host_memory_total = $var_host_memory_total + $vm_host.MemoryTotalGB
        $var_host_cpu_count = $var_host_cpu_count + $vm_host.NumCpu
        
            
    }
    
    $obj_state = New-Object –TypeName PSObject    
    $obj_state | Add-Member –MemberType NoteProperty –Name var_host_cpu –Value $var_host_cpu
    $obj_state | Add-Member –MemberType NoteProperty –Name var_host_cpu_total –Value $var_host_cpu_total
    $obj_state | Add-Member –MemberType NoteProperty –Name var_host_memory –Value $var_host_memory
    $obj_state | Add-Member –MemberType NoteProperty –Name var_host_memory_total –Value $var_host_memory_total
    $obj_state | Add-Member –MemberType NoteProperty –Name var_host_cpu_count –Value $var_host_cpu_count
    $obj_state | Add-Member –MemberType NoteProperty –Name var_drs_enabled –Value $var_drs_enabled
    $obj_state | Add-Member –MemberType NoteProperty –Name var_drs_automation_level –Value $var_drs_automation_level
    $obj_state | Add-Member –MemberType NoteProperty –Name var_vm_cpu_count –Value $var_vm_cpu_count
    $obj_state

    $arr_host_state

}