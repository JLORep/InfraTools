#Get List of Solarwinds Services
$services = Get-Service | ? { $_.name -like "*SQL*" -and $_.Status -eq "Running"}
 
#Restart each service
foreach ($service in $services)
{
	Restart-Service $service.name -Force
}