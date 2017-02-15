# vms with disks across multiple datastores
function fun_vm_split_disks{
param()

$vm_list = get-cluster "Gold" | Get-VM



$disk_array = @()

$n = $vm_list.Count
$i = 1
foreach ($vm_item in $vm_list){

    $vm_hdd = $vm_item | Get-HardDisk
    $check_disk = @()

    Foreach($hdd_item in $vm_hdd)
    {
        $datastore_directory = $hdd_item.Filename -split '\s+'
        $datastore = $datastore_directory[0]
        $check_disk += $datastore}
    $i++

    $x = 0
    foreach($check in $check_disk)
    {
        if($x -gt 0)
        {
            $y = $x -1
            if($check -ne $check_disk[$y])
            {
                $disk_array += $vm_item.Name
            }
        
        } 
        $x++    
    }

}

#$disk_array | ft -autosize


$a = $disk_array.Count
$b = 1

$arr_local_output = @()

foreach ($output_vm in $disk_array)
{
    $vm_name = Get-VM -Name $output_vm
    $hdd_item = $vm_name | Get-HardDisk
    foreach($hdd in $hdd_item)
    {

        $datastore_directory = $hdd.Filename -split '\s+'
        $datastore = $datastore_directory[0]
        if ($datastore -like "*GX_BACKUP*"){}else{$arr_local_output += $output_vm + ":  " + $datastore}
        
    }   
    $b++
}


$arr_local_output = $arr_local_output | select -uniq

$arr_local_output

}