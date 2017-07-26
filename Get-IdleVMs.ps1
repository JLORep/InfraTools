#https://deangrant.wordpress.com/2014/04/24/powercli-discover-idle-vms/

#./Get-IdleVMs.ps1 -CpuMhz 200 -DiskIO 15 -NetworkIO 2 -Percentage 85 -Days 10 -vCenter CPL28MBVCE01.uk.ventura.local

Param ([string] $CPUMhz = "100", [string] $DiskIO = "20", [string] $NetworkIO = "1", [string] $Percentage = "90", [string] $Days = "30" ) 

If (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) 
	{
	Add-PSSnapin VMware.VimAutomation.Core > $null
	}
	
#$Hosts = get-content "C:\scripts\hosts.csv" 

#Connect-VIServer CPL28MBVCE01.uk.ventura.local

$VMs = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"} 

#&{foreach($dc in Get-Datacenter){

$Output = &{ForEach ($VM in $VMs) 
	 { 
	 
	$CPUStat = Get-Stat -Entity $VM.Name -Stat cpu.usagemhz.average -Start (Get-Date).AddDays(-$Days) -Finish (Get-Date) 
	$CPUIdle = $CPUStat | Where-Object {$_.Value -le $CpuMhz} 
	$CPUDetection = ($CPUIdle.Count / $CPUStat.Count) * 100 
	
	$DiskStat = Get-Stat -Entity $VM.Name -Stat disk.usage.average -Start (Get-Date).AddDays(-$Days) -Finish (Get-Date) 
	$DiskIdle = $DiskStat | Where-Object {$_.Value -le $DiskIO} 
	$DiskDetection = ($DiskIdle.Count / $DiskStat.Count) * 100 
	
	$NetworkStat = Get-Stat -Entity $VM.Name -Stat net.usage.average -Start (Get-Date).AddDays(-$Days) -Finish (Get-Date) 
	$NetworkIdle = $NetworkStat | Where-Object {$_.Value -le $NetworkIO} 
	$NetworkDetection = ($NetworkIdle.Count / $NetworkStat.Count) * 100 
	
	
If ($CPUDetection -ge $Percentage -and $DiskDetection -ge $Percentage -and $NetworkDetection -ge $Percentage)
		{ 
		"" | Select @{N="Name";E={$VM.Name}},
		@{N="CPU Usage (Mhz)";E={[Math]::Truncate(($CPUStat.Value| Measure-Object -Average).Average)}},
		@{N="Disk I/O Usage (KBps)";E={[Math]::Truncate(($DiskStat.Value| Measure-Object -Average).Average)}},
		@{N="Network I/O Usage (KBps)";E={[Math]::Truncate(($NetworkStat.Value| Measure-Object -Average).Average)}}
		}	 
	}
	}
$Output | Export-Csv -Path C:\scripts\idlevmsCPL.csv -NoTypeInformation


