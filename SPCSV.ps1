# CSV path/File name
$contents = Import-Csv ".\JDEWEB1.csv"

# Web URL
$web = Get-SPWeb -Identity "https://icred.mmu.ac.uk/informer/" 

# SPList name
$list = $web.Lists["JDEWEB"] 

# Iterate for each list column

foreach ($row in $csv) {
    $item = $list.Items.Add();
    $item["Computer"] = $row.Computer;
    $item["Title"] = $row.Title;
    $item["KB"] = $row.KB;
    $item["IsDownloaded"] = $row.IsDownloaded;
    $item["Notes"] = $row.Notes;
    $item.Update();
}