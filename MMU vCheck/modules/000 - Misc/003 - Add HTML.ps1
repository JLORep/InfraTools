# function to convert the output of a function to HTML and add it to the report
function fun_add_html{
param($html_array,$html_title)
    
    $c = ""
    $c += '<button class="accordion">'+$html_title+'</button>'
    $c += '<div class="panel">'
    $c += '<p>'

    
    $html_local = $html_array | ConvertTo-HTML -Fragment
    $c += $html_local

    $c += '</p>'
    $c += '</div>'

    $c

}

# function to generate the cluster stats and add them to the report
function fun_add_cluster_html{
param($value,$total,$label,$limit)
    


    $var_local_percent = (($value/$total)*100)
    $var_local_percent = [math]::Round($var_local_percent,2)


    $c = ""
    

    if ($var_local_percent -gt $limit){
    Write-Host "$label" $var_local_percent "%" -foreground "red"
    $c += '<table class="red">'
    }
    else
    {
    Write-Host "$label" $var_local_percent "%" -foreground "green"
    $c += '<table class="green">'
    }
    
    $c += '  <tr>'
    $c += "    <th>$label</th>"
    $c += "    <th>$var_local_percent %</th>"
    $c += '  </tr>'
    $c += '</table>'
    $c

}

# function to generate the cluster stats and add them to the report
function fun_add_drs_html{
param($enabled,$level)
    

    $c = ""
    

    if ($enabled -eq "True"){
    $c += '<table class="green">'
    }
    else
    {
    $c += '<table class="red">'
    }
    
    $c += '  <tr>'
    $c += "    <th>DRS Status</th>"
    $c += "    <th>$enabled</th>"
    $c += '  </tr>'
    $c += '</table>'



    if ($level -eq "FullyAutomated"){
    $c += '<table class="green">'
    }
    else
    {
    $c += '<table class="red">'
    }
    
    $c += '  <tr>'
    $c += "    <th>DRS Level</th>"
    $c += "    <th>$level</th>"
    $c += '  </tr>'
    $c += '</table>'
    $c

}
