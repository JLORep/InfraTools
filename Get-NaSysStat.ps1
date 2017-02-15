Param([string]$NaIP = "0.0.0.0", [string]$NaUS = "root", [string]$NaPW = "password", [string]$Output = "Display", [int]$Interval = 5, [int]$Iterations = 0)
# Parameters:
#
#  NaIP       : IP address or Name of the Filer
#  NaUS       : Filer User Name. Default Value - root
#  NaPW       : Filer User's Password. Default Value - password.
#  Output     : Display/<File Name or Path>. Default Value - Display
#  Interval   : Interval in minutes between samples. Default Value - 5 min.
#  Iterations : Number of sample iterations. 
#               Default Value - 0, for no limit. 
#               Execution can be ended by pressing Ctrl-C  

#****************************************************************
#*** Functions                                                ***
#****************************************************************

# Calculating Delta Value between Pervious and Current Sample
Function CounterDelta ($V2, $V1)
{
  $ReturnValue = $V2 - $V1
  Return $ReturnValue
}

# Calculating Rate Value based Pervious and Current Sample
Function CounterRate ($V2, $V1, $TimeInt)
{
  $ReturnValue = ($V2 - $V1)/$TimeInt
  Return $ReturnValue
}

# Calculating Average and Percent Values based Pervious and Current Sample
Function CounterAverage ($V2, $V1, $T2, $T1)
{
  If ((($V2 - $V1) -eq 0) -or (($T2 - $T1) -eq 0)) 
  {
    $ReturnValue = 0
  }
  Else
  {
    $ReturnValue = (($V2 - $V1)/($T2 - $T1))
  }
  Return $ReturnValue
}

#****************************************************************
#*** Main                                                     ***
#****************************************************************

# Connect to Filer
$Password = ConvertTo-SecureString $NaPW -AsPlainText -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $NaUS,$Password
$Filer = Connect-NaController $NaIP -Credential $Creds

# Check Output parameter to output Performance Data. 
# If no parameter or "Display" parameter specified, 
# Performance Data only displayed on screen. If File Name/Path specified 
# Performance Data are written to Comma-Ceparated-Values file along with 
# screen output. 
If ($Output -ne "Display")
{
  $File = $Output 
}
Else
{
  $File = $Null
}
If ($File -ne $Null)
{
  If (-not $File.Contains(":\"))
  {
    $WorkingFolder = Get-Location
    $File = $WorkingFolder.Path + "\" + $File
  }
}

# Time Interval between samples in minutes. 
# By default if it's not specified, Time Interval is 5 min.
$Interval = $Interval * 60

# Get Definition of Sample Counters
$PerfCounterDef = Get-NaPerfCounter system
# BaseCounter
# Name
# * _hist [Exclude]
# Properties
# * string
# * raw: single counter value is used      
# * delta: change in counter value between two samples is used  
# * delta,no-display [Exclude]
# * rate: delta divided by the time in seconds between samples is used      
# * average: delta divided by the delta of a base counter is used      
# * percent: 100*average is used
# Unit          

# Create Array of Counters for Sample.
# Each Counter Object has next Properties:
#   Name  - Name of the counter
#   Value - Raw and calculated value of the counter
#   Base  - Name of base counter for calculation of actual value of the counter 
#            if calculation depends on base counter
#   Prop  - Type of the counter, defines method to be used to calculate actual value  
#
# First counter is Date-Time stamp of Performance Sample 
$PerfCounters =@()
 $PerfCounter = New-Object System.Object
   $PerfCounter | Add-Member -type NoteProperty -name Name -value Time
   $TimerStart = Get-Date
   $PerfCounter | Add-Member -type NoteProperty -name Value -value $TimerStart
 $PerfCounters += $PerfCounter
# Add counters based of definition of Sample Couters excluding Historical and No-Display counters.
If ($File -ne $Null) { $OutLine = "Time, " }
ForEach($Def in $PerfCounterDef)
{
  If ( -not (($Def.Name).contains("_hist")) -and -not (($Def.Properties).contains("no-display")) )
  {
    If ($File -ne $Null) { $OutLine = $OutLine + $Def.Name + ", " }
    $PerfCounter = New-Object System.Object
    $PerfCounter | Add-Member -type NoteProperty -name Name -value $Def.Name
	If ($Def.Properties -eq "string")
	{
	  $PerfCounter | Add-Member -type NoteProperty -name Value -value ""
	}
	Else
	{
	  $PerfCounter | Add-Member -type NoteProperty -name Value -value 0
	}
	$PerfCounter | Add-Member -type NoteProperty -name Base -value $Def.BaseCounter
	$PerfCounter | Add-Member -type NoteProperty -name Prop -value $Def.Properties
	$PerfCounters += $PerfCounter
  }
}
If ($File -ne $Null) { Add-Content $File $OutLine }


# Get first sample. Not to be displayed but used for calculation on next sample's actual values
$TimerStart = Get-Date
$TimerStop = Get-Date
$CurrSample = (Get-NaPerfData system).Counters
# Name
# Value

$NextSample = $True
Do
{
  # Sleep for Interval minutes before taking performance sample
  Start-Sleep $Interval
  # Calculate actual Interval in seconds between samples 
  $TimerStart = $TimerStop
  $TimerStop = Get-Date
  $TimerInterval = New-TimeSpan -Start $TimerStart -End $TimerStop
  # Save previusly take sample as PrevSample
  $PrevSample = $CurrSample
  # Take current sample
  $CurrSample = (Get-NaPerfData system).Counters

  # This code for debugging puposes only to display previous and current samples raw data.
  #Write-Host " "
  #Write-Host "*** Prev ************************************************************"
  #$PrevSample
  #Write-Host "*** Prev ************************************************************"
  #Write-Host "*** Curr ************************************************************"
  #$CurrSample
  #Write-Host "*** Curr ************************************************************"

  If ($File -ne $Null) { $OutLine = (Get-Date -format G) +", " }
  # Populate each counter in array of counters with values from sample  
  ForEach ($CurrPerf in $PerfCounters)
  {
    If ( $CurrPerf.Name -eq "Time")
	{
	  $CurrPerf.Value = $TimerStop
	}
	Else
	{
	  $Sample = $CurrSample | Where {$_.Name -eq $CurrPerf.Name}
	  $PSample = $PrevSample | Where {$_.Name -eq $CurrPerf.Name}
	  $CurrPerf.Value = $Sample.Value
	  $Base = $CurrSample | Where {$_.Name -eq $CurrPerf.Base}
	  $Base = $PrevSample | Where {$_.Name -eq $CurrPerf.Base}
	  
	  Switch ($CurrPerf.Prop)
	  {
	    "delta"
		{ 
		  $CurrPerf.Value = ( CounterDelta $CurrPerf.Value $CurrPerf.PrevV ) 
		}
        "rate" 
		{ 
		  $CurrPerf.Value = ( CounterRate $CurrPerf.Value $PSample.Value $TimerInterval.TotalSeconds )
		}
        "average" 
		{ 
  	      $Base = $CurrSample | Where {$_.Name -eq $CurrPerf.Base}
	      $BaseCurr = $Base.Value
		  $Base = $PrevSample | Where {$_.Name -eq $CurrPerf.Base}
		  $BasePrev = $Base.Value
		  $CurrPerf.Value = ( CounterAverage $CurrPerf.Value $PSample.Value $BaseCurr $BasePrev )
		}
        "percent"  
		{
  	      $Base = $CurrSample | Where {$_.Name -eq $CurrPerf.Base}
	      $BaseCurr = $Base.Value
		  $Base = $PrevSample | Where {$_.Name -eq $CurrPerf.Base}
		  $BasePrev = $Base.Value
		  $CurrPerf.Value = 100 * ( CounterAverage $CurrPerf.Value $PSample.Value $BaseCurr $BasePrev )
		}
  	    default {}
	  }
	  $CurrPerf.Value = "{0:F2}" -f $CurrPerf.Value
	  If ($File -ne $Null) { $OutLine = $OutLine + $CurrPerf.Value + ", " }
	}
  }
  
  # Display Sample actual values
  #Write-Host "*********************************************************************"
  $PerfCounters
  Write-Host "*********************************************************************"
  If ($File -ne $Null) { Add-Content $File $OutLine }
  
  $Iterations--
  If ($Iterations -eq 0 )
  {
    $NextSample = $False
  }
  If ($Iterations -eq -1 )
  {
    $Iterations = 0
  }
}
While ($NextSample)