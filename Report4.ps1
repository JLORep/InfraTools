#Open SharePoint List 
$SPServer="https://icred.mmu.ac.uk/its/informer" 
$SPAppList="/Lists/test/" 
$spWeb = Get-SPWeb $SPServer 
$spData = $spWeb.GetList($SPAppList)