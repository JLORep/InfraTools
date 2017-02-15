Get-ADComputer -Filter * -Property * | Select-Object Name,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion | Export-CSV AllWindows.csv -NoTypeInformation -Encoding UTF8