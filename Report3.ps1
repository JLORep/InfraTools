######################################################################
## TITLE: Get Disk Utilization for Data ONTAP 7-Mode via PowerShell ##
##  or getDiskUtil.ps1.                                             ##
##                              AUTHOR: vCosonok of www.cosonok.com ##
######################################################################

### START OF SCRIPT ###

# IMPORT DATAONTAP POWERSHELL TOOLKIT AND CONNECT TO 7-Mode Controller
Import-Module DataOnTap
Connect-NaController 192.168.168.70 -Credential root

# GET ALL THE DISK INSTANCES (EVERY DISK)
$diskPerfInstances = Get-NaPerfinstance disk
$numberOfDisks = $diskPerfInstances.count

# DEFINE A FEW ARRAYS
$t0_disk_busy = @()
$t0_base_for_disk_busy = @()
$t1_disk_busy = @()
$t1_base_for_disk_busy = @()

# FIRST SAMPLE FOR DISK BUSY AT T=0
$i=0
do {
       $instance = $diskPerfInstances.getvalue($i)
       $instanceName = $instance.name
       $diskPerfData = get-naperfdata -Name disk -instance $instanceName -counters disk_busy,base_for_disk_busy
       $diskPDCounters = $diskPerfData.Counters
       $t0_disk_busy += $diskPDcounters.getvalue(0).value
       $t0_base_for_disk_busy += $diskPDcounters.getvalue(1).value
       $i++
} until ($i -eq $numberOfDisks)

<#
Note: You might want to include an interval here, between the first and second sample, but, unless your system's hyper fast, it will have taken a few seconds to get from the first disk to this point anyway!
#>

# SECOND SAMPLE FOR DISK BUSY AT T=1
$i=0
do {
       $instance = $diskPerfInstances.getvalue($i)
       $instanceName = $instance.name
       $diskPerfData = get-naperfdata -Name disk -instance $instanceName -counters disk_busy,base_for_disk_busy
       $diskPDCounters = $diskPerfData.Counters
       $t1_disk_busy += $diskPDcounters.getvalue(0).value
       $t1_base_for_disk_busy += $diskPDcounters.getvalue(1).value
       $i++
} until ($i -eq $numberOfDisks)

# GET PER DISK UTILIZATION PERCENT AND SUM THEM UP
$i=0
$DiskUtilSumOfPerDiskPercents=0
do {
       $perDiskUtilPercent = 100*($t1_disk_busy.getvalue($i) - $t0_disk_busy.getvalue($i))/($t1_base_for_disk_busy.getvalue($i)-$t0_base_for_disk_busy.getvalue($i))
       "Disk $i percent utilization is: $perDiskUtilPercent"
       $DiskUtilSumOfPerDiskPercents = $DiskUtilSumOfPerDiskPercents + $perDiskUtilPercent
       $i++
} until ($i -eq $numberOfDisks)

# CALCULATE TOTAL DISK UTILIZATION OF THE SYSTEM
$diskUtil = $DiskUtilSumOfPerDiskPercents / $numberOfDisks
"TOTAL disk utilization % is: $diskUtil"

### END OF SCRIPT ###