function fun_send_mail{
param($to,$message,$attachment)
    

    # get date in ISO 8601 format
    $date = Get-Date -format "yyyy-MM-dd"

    # smtp server name
    $smtpServer = "outlook.mmu.ac.uk"
    
    # create a mail object
    $msg = new-object Net.Mail.MailMessage
    
    # create new mail server object
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    
    
    # add some email info
    $msg.From = "mmu-vcheck@mmu.ac.uk"
    $msg.To.Add($to)
    $msg.subject = "MMU vCheck - $date"
    $msg.body = $($message -join [Environment]::NewLine)
    $msg.Attachments.Add($attachment)


   
    # send email
    $smtp.Send($msg)
}