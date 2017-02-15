$shpFile1 = "\NetApp-Logic-Icons.vss"

$shpFile2 = "\NetApp-Equipment-Icons.vss"

 $FASName = read-host "Enter the FQDN of your NetApp array"

If ($FASName -eq "") { Write-Host "No selection made, script now exiting." ; exit }

function connect-visioobject ($firstObj, $secondObj)

{

 $shpConn = $pagObj.Drop($pagObj.Application.ConnectorToolDataObject, 0, 0)

 #// Connect its Begin to the 'From' shape:

 $connectBegin = $shpConn.CellsU("BeginX").GlueTo($firstObj.CellsU("PinX"))

 #// Connect its End to the 'To' shape:

 $connectEnd = $shpConn.CellsU("EndX").GlueTo($secondObj.CellsU("PinX"))

}
 
function add-visioobject ($mastObj, $item)

{

   Write-Host "Adding $item"

  # Drop the selected stencil on the active page, with the coordinates x, y

    $shpObj = $pagObj.Drop($mastObj, $x, $y)

  # Enter text for the object

    $shpObj.Text = $item

  #Return the visioobject to be used

  return $shpObj

 }

 
# Create an instance of Visio and create a document based on the Basic Diagram template.

$AppVisio = New-Object -ComObject Visio.Application

$docsObj = $AppVisio.Documents

$DocObj = $docsObj.Add("Basic Network Diagram.vst")
 
# Set the active page of the document to page 1

$pagsObj = $AppVisio.ActiveDocument.Pages

$pagObj = $pagsObj.Item(1)


# Load a set of stencils and select one to drop

$stnPath = [system.Environment]::GetFolderPath('MyDocuments') + "\My Shapes"

$stnObj1 = $AppVisio.Documents.Add($stnPath + $shpFile1)

$FlexVOLObj = $stnObj1.Masters.Item("FlexVol")

$AggrObj = $stnObj1.Masters.Item("Raid Grp Aggregate Storage")

$LUNObj = $stnObj1.Masters.Item("Cylinder")

$stnObj2 = $AppVisio.Documents.Add($stnPath + $shpFile2)

$FASObj = $stnObj2.Masters.Item("FAS3000 Double controllers")

Connect-NaController $FASName -Credential (Get-Credential)

$allAGGR = Get-NaAggr

$allVols = Get-NaVol

$allLUNs = Get-NaLun

$y = $allAGGR.Count * 1.50 / 2

$x = 1.50

$FASObj = add-visioobject $FASObj $FASName

$x = 3.50

$y += 2

Foreach ($aggr in $allAGGR) {

 $aggrObj = add-visioobject $AggrObj $aggr.Name

 connect-visioobject $FASObj $aggrObj

 $y += 1.5

  Foreach ($volume in $allVols) {

  If ($volume.ContainingAggregate -eq $aggr.Name) {

   $x += 2.50 

   $volInfo = "Volume Name: " + $volume.Name + "`r`n" + "Total Size (GB): " + "{0:n2}" -f ($volume.SizeTotal / 1gb) + "`r`n" + "Size Used: " + "{0:n2}" -f ($volume.SizeUsed / 1gb)

   $FlexVOLObj = add-visioobject $FlexVOLObj $volInfo

    connect-visioobject $aggrObj $FlexVOLObj

    Foreach ($lun in $allLUNs) {

    $lunVol = $lun.path.split("/")

     If ($lunVol[2] -eq $volume.name) {

     $x += 1

     $y += .50
    
     $lunInfo = "LUN Name: " + $lun.path + "`r`n" + "Total Size (GB): " + "{0:n2}" -f ($lun.Size / 1gb)

     $LUNObj = add-visioobject $LUNObj $lunInfo

     connect-visioobject $FlexVOLObj $LUNObj

     $x -= 1

     $y -= .50
         
     }
       
    }

   }

  }

 $x = 3.50

 $y += 2.50

}

# Resize to fit page

$pagObj.ResizeToFitContents()
