$strFilter = "computer"
 
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
 
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.SearchScope = "Subtree" 
$objSearcher.PageSize = 1000 

$objSearcher.Filter = "(objectCategory=$strFilter)"

$colResults = $objSearcher.FindAll()

foreach ($i in $colResults) 
    {
        $objComputer = $i.GetDirectoryEntry()
        gwmi win32_service -filter "startname='AD\\99903484'" -computer $objComputer | select __SERVER,Name
    }
	
	
	
	
