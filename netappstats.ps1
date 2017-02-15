# #############################################################################
# iVision - SCRIPT - POWERSHELL - NETAPP 7-MODE COMMANDS
# NAME: NetApp-Gather Volume Information
# 
# AUTHOR:  Thomas Lasswell, TechColumnist
# DATE:  2014/04/28
# EMAIL: tlasswell@techcolumnist.com
# 
# COMMENT:  This script will collect volume information including autogrow settings
#
# VERSION HISTORY
# 1.0 2014.04.28 Initial Version.
#
# TO ADD
#
# #############################################################################
 
<#
.SYNOPSIS
    NetApp-Gather Snapshot Information
 
.DESCRIPTION
    This script will collect volume information including autogrow settings
     
.EXAMPLE
PS S:\102 - Scripts> & '.\NetApp-Gather Volume Information.ps1 v1.0.ps1' -nodes filer1.company.biz,filer2.company.biz -username "domain\username" -IsVerbose
 
.EXAMPLE
PS S:\102 - Scripts> & '.\NetApp-Gather Volume Information.ps1 v1.0.ps1'
 
cmdlet NetApp-Gather Volume Information.ps1 at command pipeline position 1
Supply values for the following parameters:
nodes[0]: filer1.company.biz
nodes[1]: filer2.company.biz
nodes[2]:
username: domain\username
password: *************
 
.PARAMETER (IsVerbose)
    Use this parameter to display snap detail ( & '.\NetApp-Gather Volume Information.ps1' -IsVerbose )
 
.NOTES
Written by Thomas Lasswell, TechColumnist
Version 1.0
 
.LINK
  
#>
#Get Parameters -- nodes is each node, when finished, hit enter and it will continue
Param (
    [Parameter(Mandatory=$True)]
    [Array]$nodes,
    [Parameter(Mandatory=$True)]
    [String]$username,
    [Parameter(Mandatory=$True,ParameterSetName = 'Secret')]
    [Security.SecureString]$password,
    [switch]$IsVerbose
)
#create outfile information
$exedir= Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$currentDate= (get-date -format yyyymmdd.Hm.s)
$outdetails= ($exedir + "\" + "GatherVolumeInformation_" + $currentDate + "_Detail.csv")
 
#Load ONTAP PowerShell Toolkit
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
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
 
#function to calculate difference in dates
#declare object arrays
$objDetail = @()
 
#connect to each node individually
foreach ($node in $nodes){
    Write-Host "connecting to node $node..."
    $conn = Connect-NaController -name $node -HTTPS -Credential $cred
    $snapinfoD = @()
 
    if ( $conn -ne $null ) {
        Write-host "node connected, continuing on to snapshot calculations..."
        Write-host "gathering node volumes..."
        $vols =  Get-NaVol | ? {$_.state -eq "online" -and $_.raidstatus -notmatch "read-only"}
        if ( $vols -ne $null ) {
            foreach ($vol in $vols) {
                Write-host "`ngathering volume data for volume $vol..."
                #get snapshots
                $nasis= $null
                Write-host "    ... gathering volume details"
                $navol= Get-NaVol -Name $vol
                Write-host "    ... gathering AutoSize details"
                $navolautosize= Get-NaVolAutosize -Name $vol
                Write-host "    ... gathering Dedupe (SIS) details"
                if ($navol.Dedupe -eq "True") {$nasis= Get-NaSis -Name $vol}
                if ($nasis -eq $null){$sissched="None"}
                if ($nasis -ne $null){$sissched=$nasis.Schedule}
                #format numbers
                $ftotalsize= ConvertTo-FormattedNumber $navol.TotalSize DataSize "0.0";
                $favailable= ConvertTo-FormattedNumber $navol.Available DataSize "0.0";
                $fmaxsize= ConvertTo-FormattedNumber $navolautosize.MaximumSize DataSize "0.0";
                $fincrement= ConvertTo-FormattedNumber $navolautosize.IncrementSize DataSize "0.0";
                 
                #build array for details
                $detailprop = @{'Node'=$node;
                                'Volume'=$vol;
                                'Aggregate'=$navol.Aggregate;
                                'TotalSize'=$ftotalsize;
                                'Used'=$navol.Used;
                                'Available'=$favailable;
                                'DedupeEnabled'=$navol.Dedupe;
                                'DedupeSchedule'=$sissched;
                                'AutogrowEnabled'=$navolautosize.IsEnabled;
                                'MaxSize'=$fmaxsize;
                                'IncrementSize'=$fincrement}
                $objectD = New-Object -TypeName PSObject -Prop $detailprop
                $objDetail += $objectD
                if ($IsVerbose){
                    Write-Host "`n`nShowing Verbose Output...`n`n"
                    $detailprop
                }
            }
        }
    }
}
 
#save files
$objDetail | Select Node, Volume, Aggregate, TotalSize, Used, Available, DedupeEnabled, DedupeSchedule, AutogrowEnabled, MaxSize, IncrementSize | Export-CSV -Path $outdetails -NoTypeInformation