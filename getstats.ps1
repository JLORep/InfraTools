# Connect to Filer
$NaIP = "10.112.250.1"
$NaUS = "ad\46020944"
$NaPW = "Pa55work"

$Password = ConvertTo-SecureString $NaPW -AsPlainText -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $NaUS,$Password
$Filer = Connect-NaController $NaIP -Credential $Creds

$Stats = invoke-nassh "stats show -i 10 volume:backup_vmstore01:total_ops"

$Stats