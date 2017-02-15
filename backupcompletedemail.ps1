#Set Date format for emails
$timecomplete = (Get-Date -f "HH:MM")
 
$emailFrom = "j.lockwood@mmu.ac.uk"
$emailTo = "j.lockwood@mmu.ac.uk"
$subject = "[$vm - Backup Complete]"
$body = "Backup Details
-------------
VM Name:",$SourceVM,"
Clone Name:",$CloneName",
Target Datastore:", $TargetDS,"
Time Started:", $timestart,"
Time Completed:", $timecomplete
$smtpServer = "outlook.mmu.ac.uk"
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom,$emailTo,$subject,$body