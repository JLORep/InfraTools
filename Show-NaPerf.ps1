########################################################################
## This script accepts an instance of NaController and displays a
## window containing multiple graphs that depict a continuously
## updating picture of several controller-wide performance metrics.
## Besides using the Data ONTAP PowerShell Toolkit, the script uses
## the Google Chart API to create the graphs.
##
## Author: Clinton Knight
########################################################################

$module = Get-Module DataONTAP
if ($module -EQ $NULL)
{
	Import-Module DataONTAP
}
try
{
    $requiredVersion = New-Object System.Version(1.2)
    if ((Get-NaToolkitVersion).CompareTo($requiredVersion) -LT 0) { throw }
}
catch [Exception]
{
    Write-Host "`nThis script requires Data ONTAP PowerShell Toolkit 1.2 or higher`n" -ForegroundColor Red
    return
}

#########################################################################
## Function to find a named counter value within a perf data set.
##
## data: perf data set as returned by Get-NaPerfData
## name: name of perf data counter of interest
#########################################################################

function GetPerfValue([object]$data, [string]$name)
{
    foreach ($counter in $data.Counters)
    {
        if ($counter.Name -eq $name)
        {
            return $counter.Value
        }
    }
    return $null
}

#########################################################################
## Function to calculate rate-type perf data between two samples.
##
## counterName: name of perf data counter of interest
## data1: perf data at start of measurement interval
## data2: perf data at end of measurement interval
#########################################################################

function CalculateRateCounter([string]$counterName, [object]$data1, [object]$data2)
{
    try
    {
        $counter1 = [Decimal]::Parse((GetPerfValue $data1 $counterName))
        $counter2 = [Decimal]::Parse((GetPerfValue $data2 $counterName))
        $time1 = $data1.Timestamp
        $time2 = $data2.Timestamp
        
        return ($counter2 - $counter1) / ($time2 - $time1)
    }
    catch [Exception]
    {
       return 0.0
    }
}

#########################################################################
## Function to calculate average perf data between two samples using
## a counter value and a base counter value.
##
## counterName: name of perf data counter of interest
## baseCounterName: name of related base data counter
## data1: perf data at start of measurement interval
## data2: perf data at end of measurement interval
#########################################################################

function CalculateAverageCounter([string]$counterName, [string]$baseCounterName, [object]$data1, [object]$data2)
{
    try
    {
        $counter1 = [Decimal]::Parse((GetPerfValue $data1 $counterName))
        $counter2 = [Decimal]::Parse((GetPerfValue $data2 $counterName))
        $base1 = [Decimal]::Parse((GetPerfValue $data1 $baseCounterName))
        $base2 = [Decimal]::Parse((GetPerfValue $data2 $baseCounterName))
        
        return ($counter2 - $counter1) / ($base2 - $base1)
    }
    catch [Exception]
    {
       return 0.0
    }
}

#########################################################################
## Function to combine perf data and timestamp into a data set object
##
## dateTime: timestamp when perf data was taken
## hashtable: performance data
#########################################################################

function New-DataPoint([DateTime]$dateTime, [System.Collections.Hashtable]$hashtable)
{
  $dataPoint = new-object PSObject

  $dataPoint | add-member -type NoteProperty -Name DateTime -Value $dateTime
  $dataPoint | add-member -type NoteProperty -Name Values -Value $hashtable

  return $dataPoint
}

#########################################################################
## Function to query Data ONTAP's perf API and format results
##
## controller: NaController object to query
## interval: length in seconds between perf API calls
#########################################################################

function GetPerfData([object]$controller, [Int32]$interval)
{
    # controller-wide counters to retrieve
    $counters = "nfs_ops", "cifs_ops", "http_ops", "fcp_ops", "iscsi_ops", "read_ops", "write_ops", "total_ops",
                "net_data_recv", "net_data_sent", "disk_data_read", "disk_data_written",
                "sys_read_latency", "sys_write_latency", "sys_avg_latency",
                "cpu_busy", "cpu_elapsed_time", "avg_processor_busy", "cpu_elapsed_time1", "total_processor_busy", "cpu_elapsed_time2"
                
    # first perf API call
    $data1 = Get-NaPerfData -Name system -Instances system -Counters $counters -Controller $controller
   
    # interval
    Start-Sleep -s $interval
   
    # second perf API call
    $data2 = Get-NaPerfData -Name system -Instances system -Counters $counters -Controller $controller

    # interpret protocol data
    $cifs_ops = CalculateRateCounter cifs_ops $data1 $data2
    $nfs_ops = CalculateRateCounter nfs_ops $data1 $data2
    $iscsi_ops = CalculateRateCounter iscsi_ops $data1 $data2
    $fcp_ops = CalculateRateCounter fcp_ops $data1 $data2
    $http_ops = CalculateRateCounter http_ops $data1 $data2
    
    # interpret throughput data
    $disk_data_read = CalculateRateCounter disk_data_read $data1 $data2
    $disk_data_written = CalculateRateCounter disk_data_written $data1 $data2
    $net_data_sent = CalculateRateCounter net_data_sent $data1 $data2
    $net_data_recv = CalculateRateCounter net_data_recv $data1 $data2
    
    # interpret CPU data
    $cpu_busy = (CalculateAverageCounter cpu_busy cpu_elapsed_time $data1 $data2) * 100.0
    $avg_processor_busy = (CalculateAverageCounter avg_processor_busy cpu_elapsed_time1 $data1 $data2) * 100.0
    $total_processor_busy = (CalculateAverageCounter total_processor_busy cpu_elapsed_time2 $data1 $data2) * 100.0
    
    # interpret latency data
    $sys_read_latency = CalculateAverageCounter sys_read_latency read_ops $data1 $data2
    $sys_write_latency = CalculateAverageCounter sys_write_latency write_ops $data1 $data2
    $sys_avg_latency = CalculateAverageCounter sys_avg_latency total_ops $data1 $data2
    
    # add all performance data points to a hashtable
    $dictionary = New-Object System.Collections.Hashtable
    
    [void] $dictionary.Add("CIFS", $cifs_ops)
    [void] $dictionary.Add("NFS", $nfs_ops)
    [void] $dictionary.Add("iSCSI", $iscsi_ops)
    [void] $dictionary.Add("FCP", $fcp_ops)
    [void] $dictionary.Add("HTTP", $http_ops)

    [void] $dictionary.Add("Disk read", $disk_data_read)
    [void] $dictionary.Add("Disk written", $disk_data_written)
    [void] $dictionary.Add("Network sent", $net_data_sent)
    [void] $dictionary.Add("Network received", $net_data_recv)
    
    [void] $dictionary.Add("CPU busy", $cpu_busy)
    [void] $dictionary.Add("Average processor busy", $avg_processor_busy)
    [void] $dictionary.Add("Total processor busy", $total_processor_busy)
    
    [void] $dictionary.Add("Read", $sys_read_latency)
    [void] $dictionary.Add("Write", $sys_write_latency)
    [void] $dictionary.Add("Total", $sys_avg_latency)
   
    # create data set with timestamp and perf data
    return New-DataPoint (Get-Date) $dictionary
}

#########################################################################
## Function to load PNG image from file and draw in a PictureBox
##
## pictureBox: Windows Forms object to contain a graph
## path: path to PNG image file
#########################################################################

function ShowImage([Windows.Forms.PictureBox] $pictureBox, [string] $path)
{
    if ([System.IO.File]::Exists($path))
    {
        try
        {
            $s = [System.IO.File]::Open($path, [System.IO.FileMode]::Open);
            $image = [System.Drawing.Image]::FromStream($s);
            $s.Close();
            $pictureBox.Image = $image;
        }
        catch [Exception] {}
    }
}

#########################################################################
## Function to build Google Chart API command for an XY line chart
##
## perfData: ONTAP performance data set list
## perfMetrics: list of data types to graph
## title: chart title
#########################################################################

function GetChartRequest([System.Collections.ArrayList] $perfData, [System.Collections.ArrayList] $perfMetrics, [string] $title)
{
    # color pallette
    $colors = "FF0029", "B8753C", "0029FF", "3CB875", "2A96B8", "763DB8"
    
    # base URL
    #$url = "http://chart.apis.google.com/chart?"
    
    # chart style
    $url = "cht=lxy&"
    
    # chart size
    $url += "chs=450x300&"
    
    # chart margins
    $url += "chma=35,35,35,35|0,5&"
    
    # chart title
    $chtt = "chtt="
    $chtt += $title.Replace(" ", "+")
    $url += $chtt
    $url += "&"
    
    # line styles
    $url += "chls=1&"
    
    # grid lines
    $url += "chg=0,10&"
    
    # axes
    $url += "chxt=x,y&"
    
    # axis labels
    $url += "chxl=0:|Now|10+min|20+min|30+min|40+min|50+min|1+hr&"
    
    # axis label positions
    $url += "chxp=0,3600,3000,2400,1800,1200,600,0&"
    
    # axis label styles
    $url += "chxs=0,676767,11.5,0,lt,676767&"
    
    # series colors
    $chco = "chco="
    for ($index = 0; $index -LT $perfMetrics.Count; $index++)
    {
        $chco += $colors[$index] + ","
    }
    if ($chco.EndsWith(",")) { $chco = $chco.Substring(0, $chco.Length-1) }
    $url += $chco
    $url += "&"
    
    # data labels
    $chdl = "chdl="
    foreach ($perfMetric in $perfMetrics)
    {
        $chdl += $perfMetric + "|"
    }
    if ($chdl.EndsWith("|")) { $chdl = $chdl.Substring(0, $chdl.Length-1) }
    $url += $chdl
    $url += "&"
    
    # data label position
    $url += "chdlp=t&"
    
    [Decimal] $maxPerfValue = 0.0
    
    $encodedData = "chd=t:"

    foreach ($perfMetric in $perfMetrics)
    {
        $encodedDataX = New-Object System.Collections.ArrayList
        $encodedDataY = New-Object System.Collections.ArrayList
    
        if ($perfData -NE $null)
        {
            $newestTime = $perfData[$perfData.Count-1].DateTime
    
            for ($index = 0; $index -LT $perfData.Count; $index++)
            {
                $time = $perfData[$index].DateTime
                $differenceSeconds = [Convert]::ToDouble(3600 - $newestTime.Subtract($time).TotalSeconds)
                $scaledSecondsValue = $differenceSeconds / 36;
                $formattedSecondsValue = [string]::Format("{0:0.#}", $scaledSecondsValue);
                [void] $encodedDataX.Add($formattedSecondsValue)
        
                $perfValue = $perfData[$index].Values.Item($perfMetric)
                $formattedPerfValue = [string]::Format("{0:0.#}", $perfValue);
                [void] $encodedDataY.Add($formattedPerfValue)
            
                # latch max perf value (needed for adaptive Y-axis)
                if ($perfValue -GT $maxPerfValue) { $maxPerfValue = $perfValue }
            }
        }
        else
        {
            # create some zeroes so charts appear even if there is no data
            [void] $encodedDataX.Add("0.0")            
            [void] $encodedDataX.Add("0.0")
            [void] $encodedDataY.Add("0.0")
            [void] $encodedDataY.Add("0.0")
        }
        
        $encodedData += [System.String]::Join(",", $encodedDataX.ToArray())
        $encodedData += "|"
        $encodedData += [System.String]::Join(",", $encodedDataY.ToArray())
        $encodedData += "|"
    }
    
    if ($encodedData.EndsWith("|")) { $encodedData = $encodedData.Substring(0, $encodedData.Length-1) }
    $url += $encodedData
    $url += "&"
    
    # round to next multiple of ten
    $maxPerfValue = [Convert]::ToInt32([Math]::Ceiling($maxPerfValue / 10.0) * 10.0);
    
    # axis scaling
    $chds = "chds="
    foreach ($perfMetric in $perfMetrics)
    {
        $chds += "0,100,0," + $maxPerfValue + ","
    }
    if ($chds.EndsWith(",")) { $chds = $chds.Substring(0, $chds.Length-1) }
    $url += $chds
    $url += "&"

    # axis ranges
    $url += "chxr=0,0,3600|1,0," + $maxPerfValue + "&"
        
    return $url
}

#########################################################################
## Function to invoke Google Chart API
##
## request: HTTP POST payload with chart data
## filename: path to write PNG chart file
## random: random string to prevent HTTP caching
#########################################################################

function GetChart([string]$request, [string]$filename, [string]$random)
{
    try
    {
        $url = "http://chart.apis.google.com/chart?chid=" + $random
        $buffer = [System.Text.Encoding]::ASCII.GetBytes($request)

        [Net.HttpWebRequest] $req = [Net.WebRequest]::create($url)
        $req.method = "POST"
        $req.ContentType = "application/x-www-form-urlencoded"
        $req.ContentLength = $buffer.length
        $req.TimeOut = 5000

        $reqst = $req.getRequestStream()
        $reqst.write($buffer, 0, $buffer.length)
        $reqst.flush()
        $reqst.close()


        [Net.HttpWebResponse] $res = $req.getResponse()
        $resst = $res.getResponseStream()

        $sr = New-Object IO.BinaryReader($resst)
        $sr.ReadBytes(1mb) | Set-Content $filename -enc byte

        $sr.close()
        $resst.close()
        
    } catch [Exception] {}
}


#########################################################################
## Main script
#########################################################################

# connect to controller
$controller = $null
if ($args[0] -EQ $null)
{
    Write-Error -Message "Please specify a Data ONTAP controller."
    return
}
elseif ($args[0] -is [string])
{
    # try RPC
    $controller = Connect-NaController $args[0]
    
    # fall back to HTTP
    if ($controller -EQ $null)
    {
        $cred = $host.ui.PromptForCredential("Need credentials for " + $args[0], "Please enter your user name and password.", "", "")
        $controller = Connect-NaController $args[0] -Transient -Credential $cred
    }
}
elseif ($args[0] -is [NetApp.Ontapi.Filer.NaController])
{
    $controller = $args[0]
}

if ($controller -EQ $null)
{
    Write-Error -Message "Failed to connect to controller $args[0]"
    return
}

# set up random number generator, used to prevent HTTP chart caching
$rand = New-Object System.Random([Int32]((Get-Date).Ticks -band 0x00000000ffff))

# set up metrics lists for each chart
$protocolMetrics = "CIFS", "NFS", "iSCSI", "FCP", "HTTP"
$cpuMetrics = "CPU busy", "Average processor busy", "Total processor busy"
$throughputMetrics = "Disk read", "Disk written", "Network sent", "Network received"
$latencyMetrics = "Read", "Write", "Total"

# set up image file paths in TEMP directory
$tempDir = ${env:TEMP}
$protocolOpsImageFile = $tempDir + "\" + $controller.Name + "_protocolOps.png"
$cpuBusyImageFile = $tempDir + "\" + $controller.Name + "_cpuBusy.png"
$throughputImageFile = $tempDir + "\" + $controller.Name + "_throughput.png"
$latencyImageFile = $tempDir + "\" + $controller.Name + "_latency.png"

# delete old image files
if ([System.IO.File]::Exists($protocolOpsImageFile)) { try { [System.IO.File]::Delete($protocolOpsImageFile) } catch [Exception] {} }
if ([System.IO.File]::Exists($cpuBusyImageFile)) { try { [System.IO.File]::Delete($cpuBusyImageFile) } catch [Exception] {} }
if ([System.IO.File]::Exists($throughputImageFile)) { try { [System.IO.File]::Delete($throughputImageFile) } catch [Exception] {} }
if ([System.IO.File]::Exists($latencyImageFile)) { try { [System.IO.File]::Delete($latencyImageFile) } catch [Exception] {} }

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# set up window frame with four graphs
$form = New-Object Windows.Forms.Form
$form.Text = "Data ONTAP performance  (" + $controller.Name + " / " + $controller.Address + ")"
$form.width = 950
$form.height = 670
$form.BackColor = [System.Drawing.Color]::White;

$protocolsPictureBox = New-Object Windows.Forms.PictureBox
$protocolsPictureBox.Width = 450
$protocolsPictureBox.Height = 300
$protocolsPictureBox.Location = New-Object System.Drawing.Point(20,20)

$cpuUtilizationPictureBox = New-Object Windows.Forms.PictureBox
$cpuUtilizationPictureBox.Width = 450
$cpuUtilizationPictureBox.Height = 300
$cpuUtilizationPictureBox.Location = New-Object System.Drawing.Point(470,20)

$throughputPictureBox = New-Object Windows.Forms.PictureBox
$throughputPictureBox.Width = 450
$throughputPictureBox.Height = 300
$throughputPictureBox.Location = New-Object System.Drawing.Point(20,320)

$latencyPictureBox = New-Object Windows.Forms.PictureBox
$latencyPictureBox.Width = 450
$latencyPictureBox.Height = 300
$latencyPictureBox.Location = New-Object System.Drawing.Point(470,320)

$form.controls.add($protocolsPictureBox)
$form.controls.add($cpuUtilizationPictureBox)
$form.controls.add($throughputPictureBox)
$form.controls.add($latencyPictureBox)

$form.Add_Shown( { $form.Activate() } )
$form.Add_Paint(
    {
        ShowImage $protocolsPictureBox $protocolOpsImageFile
        ShowImage $cpuUtilizationPictureBox $cpuBusyImageFile
        ShowImage $throughputPictureBox $throughputImageFile
        ShowImage $latencyPictureBox $latencyImageFile
    }
)

# set up perf data list
$perfDataList = New-Object System.Collections.ArrayList

# set up data collection loop timer
$count = 0;
$firstRun = $true;
$timer = New-Object System.Windows.Forms.Timer
$timer.Enabled = $true
$timer.Interval = 500
$timer.Add_Tick(
    {
        $count += 1
        
        if (($count -LT 40) -AND !$firstRun) { return }
        
        $firstRun = $false;
        $count = 0;
        
        # get ONTAP performance data set, averaged over five seconds
        $perfData = GetPerfData $controller 5

        # add new data set to the list
        [void] $perfDataList.Add($perfData);
        
        # purge data over an hour old
        $now = Get-Date
        while (($perfDataList.Count -GT 0) -AND ($now.Subtract($perfDataList[0].DateTime).TotalSeconds -GT 3600))
        {
            [void] $perfDataList.RemoveAt(0);
        }

        # get protocol chart
        $request = GetChartRequest $perfDataList $protocolMetrics "Protocols (ops/sec)"
        GetChart $request $protocolOpsImageFile $rand.next()

        # get CPU chart
        $request = GetChartRequest $perfDataList $cpuMetrics "CPU Utilization (%)"
        GetChart $request $cpuBusyImageFile $rand.next()

        # get throughput chart
        $request = GetChartRequest $perfDataList $throughputMetrics "I/O Throughput (KB/sec)"
        GetChart $request $throughputImageFile $rand.next()

        # get latency chart
        $request = GetChartRequest $perfDataList $latencyMetrics "Controller Average Latency (msec)"
        GetChart $request $latencyImageFile $rand.next()

        # trigger GUI refresh
        $form.Refresh()
    })
$timer.Start()

[void] $form.ShowDialog()
$timer.Enabled = $false
return