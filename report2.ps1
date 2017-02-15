################ get_max_avg_cpu.ps1 ###########
# Quick and very dirty graphing of DFM data by JK-47.com
####################################################
# Make an empty hashtable
$foo = @{}
# Read in the cli filer name
$filername=$args[0]
#Populate a var with the dfm performance data
$DFMdata = dfm perf data retrieve -o $filername -C system:avg_processor_busy -d 7889231 -S simple -m max -s 3600 | select-object -skip 3
# Do some excel voodoo
$excel=New-Object -COM "Excel.Application"
$excel.Visible=$true
$excel.Usercontrol=$true
$Workbook=$excel.Workbooks.add()
# Add a Worksheet
$Worksheet=$Workbook.Worksheets.Item(1)
# Split the DFM data into 2 columns.
$row=1
$DFMdata | % {
$s = $_.Split("`t")
      $Workbook.ActiveSheet.Cells.Item($row,1).Value2 = $s[0]
      $Workbook.ActiveSheet.Cells.Item($row,2).Value2 = $s[1]
$row++
}
# Add a chart of the active data
$objRange=$Worksheet.UsedRange
$colCharts=$excel.Charts
$objChart=$colCharts.Add()
$objChart.ChartType=75
$a=$objChart.Activate