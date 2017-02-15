foreach ($aggr in Get-NaAggr){
        $voltotal = foreach ($volume in get-navol -Aggregate $aggr) {Get-NaVol $volume.name | select @{name="Total";e={[math]::truncate($_.TotalSize / 1GB)}},@{name="Snap";e={[math]::truncate($_.SnapshotBlocksReserved / 1GB)}}}
        $aggrused = Get-NaAggr -name $aggr |Select @{name="Used";e={[math]::truncate($_.SizeUsed / 1GB)}}
        $committed = ($voltotal | Measure-Object 'Total' -Sum).Sum
        Get-NaAggr -name $aggr | select @{n="Controller";e={$controller}},Name,@{name="Total";e={[math]::truncate($_.TotalSize / 1GB)}},@{name="Used";e={$aggrused.used}},@{name="Used%";e={[math]::round(([decimal] $_.sizeused / $_.totalsize)*100)}},@{name="Committed";e={$committed}},@{name="Committed%";e={[math]::round(([decimal] $committed / ($_.TotalSize / 1GB))*100)}}
        }