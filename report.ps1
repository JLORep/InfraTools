param(  
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,HelpMessage="Enter the FQDN of your NetApp 7-MODE Controller")]  
        $Controller,
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,HelpMessage="Enter the Username for Accessing the Controller")]  
        $UserName,
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,HelpMessage="Enter the Password for Accessing the Controller")]  
        $Password,
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,HelpMessage="Enter the Location to save the csv file")]  
        $Location          
      ) 

Import-Module DataONTAP -ErrorAction SilentlyContinue

$ControllerPassword = ConvertTo-SecureString -String $Password -AsPlainText -force
$ControllerCredential = New-Object System.Management.Automation.PsCredential($UserName,$ControllerPassword)



Foreach ($filer in $controller)
{

Connect-NaController -Name $filer -Credential $ControllerCredential

Write-Verbose "Collecting Volume Information for $filer" -Verbose



Get-NaVol | Select @{Name="VolumeName";Expression={$_.name}},@{Name="TotalSize(GB)";Expression={[math]::Round([decimal]$_.SizeTotal/1gb,2)}},@{Name="AvailableSize(GB)";Expression={[math]::Round([decimal]$_.SizeAvailable/1gb,2)}},@{Name="UsedSize(GB)";Expression={[math]::Round([decimal]$_.SizeUsed/1gb,2)}},@{Name="SnapshotBlocksReserved(GB)";Expression={[math]::Round([decimal]$_.SnapshotBlocksReserved/1gb,2)}}`
,SnapshotPercentReserved,Aggregate,IsDedupeEnabled,type,DiskCount,RaidStatus,Autosize,ChecksumStyle,state | Export-Csv -LiteralPath $Location\$filer.csv -Force -NoTypeInformation -Verbose


Write-Verbose "Completed Collecting Volume Information for $filer" -Verbose

}





