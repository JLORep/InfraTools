# – SnapReminder V1.0 By Virtu-Al – http://virtu-al.net
#
# Please use the below variables to define your settings before use
# function GetSnapList uses http://virtualcurtis.wordpress.com/2011/10/02/find-virtual-machine-snapshots-with-powercli/


$vCenterServer = "Auron.mmu.ac.uk"
$smtpServer = "outlook.mmu.ac.uk"
$MailFrom = "j.lockwood@mmu.ac.uk"
$AgeOfSnap = 30
$CredentialID = “ad\46020944”


function Log([string]$path, [string]$value)
{
    Add-Content -Path “$($Path)$($LogDate).txt” -Value $value
}

# Loading Snapins
function LoadSnapin{
  param($PSSnapinName)
  if (!(Get-PSSnapin | where {$_.Name   -eq $PSSnapinName})){
    Add-pssnapin -name $PSSnapinName
  }
}
LoadSnapin -PSSnapinName   “VMware.VimAutomation.Core”

function Find-User ($username){
    if ($username -ne $null)
    {
        $usr = (($username.split(“\”))[1])
        $root = [ADSI]””
        $filter = (“(&(objectCategory=user)(samAccountName=$Usr))”)
        $ds = new-object system.DirectoryServices.DirectorySearcher($root,$filter)
        $ds.PageSize = 1000
        $ds.FindOne()
    }
}

function GetSnapList
{

$myVMs = Get-VM
$VMsWithSnaps = @()

foreach ($vm in $myVMs) 
{
    $vmView = $vm | Get-View
    if ($vmView.snapshot -ne $null) 
    {
         $SnapshotEvents = Get-VIEvent -Entity $vm -type info -MaxSamples 1000 | Where { $_.FullFormattedMessage.contains(“Create virtual machine snapshot”)}
        try 
        {
            $user = $SnapshotEvents[0].UserName
            $time = $SnapshotEvents[0].CreatedTime
        } 
        catch [System.Exception] 
        {
                $user = $SnapshotEvents.UserName
                $time = $SnapshotEvents.CreatedTime
        }
       $VMInfo = “” | Select “VM”,”CreationDate”,”User”
       $VMInfo.”VM” = $vm.Name
       $VMInfo.”CreationDate” = $time
       $VMInfo.”User” = $user
       $VMsWithSnaps += $VMInfo
    }
}

#Causes the array to be doubled
#$VMsWithSnaps | Sort CreationDate

return $VMsWithSnaps
}

function SnapMail ($Mailto, $snapshot)
{
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $MailFrom
    $msg.To.Add($Mailto)
    $msg.Subject = “Snapshot Reminder”
    $MailText = “This is a reminder that you have a snapshot active on $($snapshot.VM) which was taken on $($snapshot.Created)”        
    $msg.Body = $MailText
    $smtp.Send($msg)
    $VMDiskSize = [Math]::Round(($snapshot.SizeGB),2)
    Log -Path $OutputEmailAudit -Value “$($Mailto),$($snapshot.VM),$($snapshot.Created),$($VMDiskSize) GB”    
}

#Sanitize if a notification is sent to owner of Snap
function Sanitize ($SnapInfo,[string]$VMName)
{
    [string]$SnapDescription=$SnapInfo.Description
    [string]$SnapName=$SnapInfo.Name
    
    switch -wildcard ($VMName)
    {
        “*abc*” {return $false}
        “*xyz*” {return $false}
        “*123*” {return $false}
        “*xp*” {return $false}
        #”*templates*” {return $false}
    }    
    
    switch -wildcard ($SnapDescription)
    {
        “*abc*” {return $false}
        “*xyz*” {return $false}
        “*123*” {return $false}
        “*xp*” {return $false}
        #”*templates*” {return $false}
    }    
    
    switch -wildcard ($SnapName)
    {
        “*abc*” {return $false}
        “*xyz*” {return $false}
        “*123*” {return $false}
        “*xp*” {return $false}
        #”*templates*” {return $false}
        default {return $true}
    }
}

[double]$SnapSpaceUsed=0
[int]$SnapCount=0
$StartDate = Get-Date
$LogDate = “$($StartDate.Month)-$($StartDate.Day)-$($StartDate.Year)-$($StartDate.Hour)-$($StartDate.Minute)-$($vCenterServer)”
$cred = Get-Credential $CredentialID
Connect-VIServer -server $vCenterServer -credential $cred
Log -Path $Output -Value “Starting process as $($Cred.Username) connecting to $($vCenterServer) at $($StartDate)”

$vmlist = GetSnapList

#Get a list of machines that have snapshots
#Loop through it
foreach ($snapdata in $vmlist)
{
    Write-Host “Starting VM – $($snapdata.vm)”
    #Start process that shows creation date is l
     if($snapdata.CreationDate -lt ((Get-Date).AddDays(-$AgeOfSnap)))
    {
      #Get a list of snaphosts per vm
      #Loop through the list of VM’s
      $snapPerVM = Get-VM -Name $snapdata.vm | Get-SnapShot
      foreach($snap in $snapPerVM)
      {            
           [Boolean]$ProcessNotification = Sanitize -SnapInfo $snap -VMName $snapdata.vm
               Log -Path $Output -Value “*************************************************”
            Log -Path $Output -Value “Starting VM – $snapdata.vm”
            Log -Path $Output -Value “Process : $($ProcessNotification) : Snap : $($snap)” 
           
           if($ProcessNotification -eq $true -and $snapdata.User -ne $null)
           {
                $mailto = ((Find-User $snapdata.User).Properties)
                $mailattr = $mailto.mail
                
                if($mailattr -ne $null)
                {
                    SnapMail $mailto.mail $snap
                    Write-Host “$($mailto.mail) – $($snapdata.VM) and $($snap)”
                    Log -Path $Output -Value “MailTo Value : $($mailto.mail) : VMName : $($snapdata.VM) : SnapData : $($snap)”                    
                }
                else
                {
                    $FirstName = $mailTo.givenname
                    $LastName = $mailTo.sn
                    $FirstName = $FirstName -replace ” “, “”
                    $LastName = $LastName -replace ” “, “.”
                    
                    if($FirstName -eq $null)
                    {
                        $emailAddress = “steve@example.com”
                    }
                    else
                    {
                        $emailAddress = “$($FirstName).$($LastName)@example.com”
                    }
                    
                    SnapMail $emailAddress $snap
                    Write-Host “$($emailAddress) – $($snapdata.VM) and $($snap)”
                    Log -Path $Output -Value “EmailAddress : $($emailAddress) : VMName : $($snapdata.VM) : SnapData : $($snap)”
                    $emailAddress=””
                }
                
            $SnapCount++
            $SnapSpaceUsed += $snap.SizeGB
            
            Log -Path $Output -Value “Ending VM – $snapdata.vm”
            Log -Path $Output -Value “*************************************************”
            
            }
            else
            {
                Write-Host “Not sending email for $($snapdata) for $($snapdata.VM)”
                Log -Path $OutputErrors -Value ”    Not sending email for VMName : $($snapdata.VM) : SnapData : $($snap)”
            }
        }
    }
    
}

$SnapSpaceUsed = [Math]::Round($SnapSpaceUsed,2)
Log -path $Output -Value “Number of snaps notified via email : $($SnapCount)  `r`nAmount of spaced the snapshots consumed – $($SnapSpaceUsed) GB”

Disconnect-VIServer -Server $vCenterServer -Force -Confirm:$false
$EndDate = Get-Date
Log -Path $Output -Value “Ending process as $($Cred.Username) connecting to $($vCenterServer) at $($EndDate)”