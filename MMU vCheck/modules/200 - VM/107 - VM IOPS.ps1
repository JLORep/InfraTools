# vms with iops over 100
function fun_vm_iops{
param($arr_vm_list_simple)

$metrics = "virtualdisk.numberwriteaveraged.average","virtualdisk.numberreadaveraged.average"
$start = (Get-Date).AddMinutes(-5)
$report = @()
 
$vms = $arr_vm_list_simple | where {$_.PowerState -eq "PoweredOn"}
$stats = Get-Stat -Realtime -Stat $metrics -Entity $vms -Start $start
$interval = $stats[0].IntervalSecs
 
$hdTab = @{}
foreach($hd in (Get-Harddisk -VM $vms)){
    $controllerKey = $hd.Extensiondata.ControllerKey
    $controller = $hd.Parent.Extensiondata.Config.Hardware.Device | where{$_.Key -eq $controllerKey}
    $hdTab[$hd.Parent.Name + "/scsi" + $controller.BusNumber + ":" + $hd.Extensiondata.UnitNumber] = $hd.FileName.Split(']')[0].TrimStart('[')
}
 
$report = $stats | Group-Object -Property {$_.Entity.Name},Instance | %{
    New-Object PSObject -Property @{
        VM = $_.Values[0]
        Disk = $_.Values[1]
        IOPSMax = ($_.Group | `
            Group-Object -Property Timestamp | `
            %{$_.Group[0].Value + $_.Group[1].Value} | `
            Measure-Object -Maximum).Maximum / $interval
        Datastore = $hdTab[$_.Values[0] + "/"+ $_.Values[1]]
    } | where {$_.IOPSMax -gt 100}
}
 
$report

}