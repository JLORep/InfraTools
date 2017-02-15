#Set Date format for emails
$timestart = (Get-Date -f "HH:MM")
 
$emailFrom = "j.lockwood@mmu.ac.uk"
$emailTo = "j.lockwood@mmu.ac.uk"
$subject = "[$vm - Backup Started]"
$body = "Backup Details
-------------
VM Name:",$vm,"
Clone Name:","$vm-$date","
Target Datastore:", $customer.BackupDS,"
Time Started:", $timestart
 
$smtpServer = "outlook.mmu.ac.uk"
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom,$emailTo,$subject,$body)
