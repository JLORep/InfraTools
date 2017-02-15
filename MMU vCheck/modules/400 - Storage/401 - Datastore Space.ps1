# get any VM that has any value of ballooned memory or swapped memory over 100MB
function fun_datastore_space{
param()

   
    #$vm_datastore = get-cluster "Gold" | get-vmhost | get-datastore | Where-Object { $_.Name -like '*Gold*' -and $_.FreeSpaceGB -lt 250} | Sort-Object -Property FreespaceGB -Descending:$true
    

    $arr_local = @()
    $vm_datastores = get-cluster "Gold" | get-vmhost | get-datastore | Where-Object { $_.CapacityGB -gt 100} | Sort-Object -Property FreespaceGB -Descending:$false

    foreach($vm_datastore in $vm_datastores){

    $local_free = ([Math]::Floor([decimal]($vm_datastore.FreeSpaceGB)))
    $local_total = ([Math]::Floor([decimal]($vm_datastore.CapacityGB)))
    $local_percent = ([Math]::Floor([decimal]($vm_datastore.FreeSpaceGB / $vm_datastore.CapacityGB *100)))


     #$vm_datastore | fl 
        $obj_local = New-Object –TypeName PSObject    
        $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $vm_datastore.Name
        $obj_local | Add-Member –MemberType NoteProperty –Name FreeSpaceGB –Value $local_free
        $obj_local | Add-Member –MemberType NoteProperty –Name CapacityGB –Value $local_total
        $obj_local | Add-Member –MemberType NoteProperty –Name PercentFree –Value $local_percent
        $arr_local += $obj_local

      }

    $arr_local



}
