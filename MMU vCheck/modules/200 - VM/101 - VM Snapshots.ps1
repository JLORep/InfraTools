# get any VM that has snapshots older than x days and find the user that took it
function fun_vm_snapshots{
    
    $var_snaphot_age = 10
    $arr_local = @()

    foreach ($snap in Get-VM | Get-Snapshot | Where {$_.Created -lt ((Get-Date).AddDays(-$var_snaphot_age))})
    {      
        $snapevent = Get-VIEvent -Entity $snap.VM -Types Info -Finish $snap.Created -MaxSamples 1 | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}
        if ($snapevent -ne $null){
           
            # get the rough size of the snapshot in GB
            $var_snapshot_size = ([Math]::Floor([decimal]($snap.SizeGB)))
            $var_snapshot_size = $var_snapshot_size.ToString() + " GB"

            # find the display name of user that created the snapshot in AD
            $ad_user = fun_find_ad_user -username $snapevent.UserName
            if($ad_user){$ad_username = $ad_user.Properties.displayname[0]}
            else{$ad_username = $snapevent.UserName}

            # add to an object
            $obj_local = New-Object –TypeName PSObject    
            $obj_local | Add-Member –MemberType NoteProperty –Name VM –Value $snap.VM
            $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $snap
            $obj_local | Add-Member –MemberType NoteProperty –Name Username –Value $ad_username
            $obj_local | Add-Member –MemberType NoteProperty –Name Size –Value $var_snapshot_size            
            $obj_local | Add-Member –MemberType NoteProperty –Name Created –Value $snap.Created.DateTime            
            #$obj_local | Add-Member –MemberType NoteProperty –Name Description –Value $snap.Description

            # add object to an array
            $arr_local += $obj_local

        }
    }
    $arr_local
}
