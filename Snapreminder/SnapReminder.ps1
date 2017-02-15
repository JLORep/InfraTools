# Snapshot Reminder Email script based on - SnapReminder V1.0 By Virtu-Al
# modified by Leon Scheltema 
# Please use the below variables to define your settings before use


if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{
	Add-PSSnapin VMware.VimAutomation.Core
}

$smtpServer = "outlook.mmu.ac.uk"
$MailFrom = "j.lockwood@mmu.ac.uk"
$VC1 = "Auron.ad.mmu.ac.uk"
$default_mail_tgt = "ss@mmu.ac.uk"
# Please define max. allowed age of VMWare snapshot
$Age = 14
 
function Find-User ($username){
#    if ($username -ne $null)
		if ($username -ne $null -and $username -ne "Administrator")
    {
        $usr = (($username.split("\"))[1])
        $root = [ADSI]""
        $filter = ("(&(objectCategory=user)(samAccountName=$Usr))")
        $ds = new-object system.DirectoryServices.DirectorySearcher($root,$filter)
        $ds.PageSize = 1000
        $ds.FindOne()
    }
}
 
function Get-SnapshotTree{
    param($tree, $target)
 
    $found = $null
    foreach($elem in $tree){
        if($elem.Snapshot.Value -eq $target.Value){
            $found = $elem
            continue
        }
    }
    if($found -eq $null -and $elem.ChildSnapshotList -ne $null){
        $found = Get-SnapshotTree $elem.ChildSnapshotList $target
    }
 
    return $found
}
 
function Get-SnapshotExtra ($snap)
{
    $guestName = $snap.VM   # The name of the guest
 
    $tasknumber = 999       # Windowsize of the Task collector
 
    $taskMgr = Get-View TaskManager
 
    # Create hash table. Each entry is a create snapshot task
    $report = @{}
 
    $filter = New-Object VMware.Vim.TaskFilterSpec
    $filter.Time = New-Object VMware.Vim.TaskFilterSpecByTime
    $filter.Time.beginTime = (($snap.Created).AddSeconds(-5))
    $filter.Time.timeType = "startedTime"
    $filter.State = "success"
    $filter.Entity = New-Object VMware.Vim.TaskFilterSpecByEntity
    $filter.Entity.recursion = "self"
    $filter.Entity.entity = (Get-Vm -Name $snap.VM.Name).Extensiondata.MoRef
 
    $collectionImpl = Get-View ($taskMgr.CreateCollectorForTasks($filter))
 
    $dummy = $collectionImpl.RewindCollector
    $collection = $collectionImpl.ReadNextTasks($tasknumber)
    while($collection -ne $null){
        $collection | where {$_.DescriptionId -eq "VirtualMachine.createSnapshot" -and $_.State -eq "success" -and $_.EntityName -eq $guestName} | %{
            $row = New-Object PsObject
            $row | Add-Member -MemberType NoteProperty -Name User -Value $_.Reason.UserName
            $vm = Get-View $_.Entity
            $snapshot = Get-SnapshotTree $vm.Snapshot.RootSnapshotList $_.Result
            if ( $snapshot -ne $null)
            {
                $key = $_.EntityName + "&" + ($snapshot.CreateTime.ToLocalTime().ToString())
                $report[$key] = $row
            }
        }
        $collection = $collectionImpl.ReadNextTasks($tasknumber)
    }
    $collectionImpl.DestroyCollector()
 
    # Get the guest's snapshots and add the user
    $snapshotsExtra = $snap | % {
        $key = $_.vm.Name + "&" + ($_.Created.ToLocalTime().ToString())
        if($report.ContainsKey($key)){
            $_ | Add-Member -MemberType NoteProperty -Name Creator -Value $report[$key].User
            write-host $report[$key].User is creator of $key
            
        }
        $_
    }
    $snapshotsExtra
}
 
Function SnapMail ($Mailto, $snapshot, $usrName)
{
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $MailFrom
    if ( $MailTo -ne "" -and $MailTo -ne $null)
    {
        #Write "Woulde be adding $Mailto to the recipients list"
        $msg.To.Add($Mailto)
        $msg.Subject = "Snapshot Reminder"
    }
    else
    {
        if ( $usrName -ne "" -and $usrName -ne $null)
        {
            $msg.Subject = "Snapshot Reminder for $usrName"
        }
        else
        {
            $msg.Subject = "Snapshot Reminder for Snapshot with unknown owner"
        }        
        $msg.To.Add($default_mail_tgt)
    }
 
 
$MailText = @"
This is a reminder that you have a snapshot active on $($snapshot.VM) which was taken on $($snapshot.Created).
Name: $($snapshot.Name)
Description: $($snapshot.Description)

vmware reccomend a maximum snapshot age of 48hrs. This is because when a snapshot is taken, the base disk is preserved & a Delta (or "difference") Disk is created. As each day passes the Delta gets larger and consumes more & more Space / IO.

Therefore by forgetting about this snapshot, you are putting our whole estate under unnecessary pressure. If you need a snapshot to live longer than the very generous 14 days i have alotted, then simply clone the VM. 

I'm afraid you will be pestered by these emails every day that they survive past the allotted 14 days. It is YOUR responsibility to remove these snapshots, or ensure that they are removed in a timely manner

Thanks for you understanding,

Yours Faithfully, 

Servers & Storage Team

"@  
 
    $msg.Body = $MailText
    $smtp.Send($msg)
}
 
Connect-VIServer $VC1

# -------------- Summary  File Setup-----------------------------

# Output File
$strOutFile = "C:\Scripts\SnapReminder\snapshot_notify_list.htm"

# HTML/CSS style for the output file
$head = "<style>"
$head = $head + "BODY{background-color:white;}"
$head = $head + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$head = $head + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#018AC0}"
$head = $head + "TD{border-width: 1px;padding-left: 10px;padding-right: 10px;border-style: solid;border-color: black;background-color:e5e5e5}"
$head = $head + "</style>"

$strSubject = "Snapshot list - " + (get-date -DisplayHint date)
$strBody = "Attached is the list of Snapshots and their Creators"
$strMail = "<H2><u>" + $strSubject + "</u></H2>"


# -------------- Logic -----------------------------
$myCol = @()

foreach ($snap in (Get-Cluster "DBS","EDGE","GOLD","MANAGEMENT","PRE-NSX","PRE-NSX-SILVER" | Get-VM | Get-Snapshot | Where {$_.Created -lt ((Get-Date).AddDays(-$Age))}))
{
    $SnapshotInfo = Get-SnapshotExtra $snap
    $usr = Find-User $SnapshotInfo.Creator
    $mailto = $usr.Properties.mail
    SnapMail $mailto $SnapshotInfo $usr.Properties.displayname

	$myObj = "" | Select-Object VM, Snapshot, Created, CreatedBy, EmailedTo, Description
	
    $myObj.VM = $snap.vm.name
	$myObj.Snapshot = $snap.name
	$myObj.Created = $snap.created
	if ( $usr -ne $null)
    {
        [String]$a = $usr.Properties.name
        $myObj.CreatedBy = $a
    }
    else
    {
        $myObj.CreatedBy = "Unknown Creator"
    }
    
    if ( $mailto -eq "" -or $mailto -eq $null)
    {
        $myObj.EmailedTo = $default_mail_tgt
    }
    else
    {
        [String]$a = $usr.Properties.mail
        $myObj.EmailedTo = $a
    }
    
    $myObj.Description = $snap.Description
    
	$myCol += $myObj

}

# Write the output to an HTML file
 $myCol | Sort-Object VM | ConvertTo-HTML -Head $head -Body $strMail | Out-File $strOutFile

$strFrom = $MailFrom
$strTo = $default_mail_tgt

# Mail the output file
$msg = new-object Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($strOutFile)
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg.From = $strFrom
$msg.To.Add($strTo)
$msg.Subject = $strSubject
$msg.IsBodyHtml = 1
$msg.Body = Get-Content $strOutFile
$msg.Attachments.Add($att)
$msg.Headers.Add("message-id", "<3BD50098E401463AA228377848493927-1>")	# Adding a Bell Icon for Outlook users

$smtp.Send($msg)

Disconnect-VIServer $VC1 -confirm:0