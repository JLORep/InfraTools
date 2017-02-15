
#region readme





#endregion readme


#region setup
if(!(Get-module VMware.VimAutomation.Core)){Import-Module VMware.VimAutomation.Core}

connect-viserver "auron.ad.mmu.ac.uk"

$var_cluster = Get-Cluster "Gold"
$arr_vm_list = Get-View -ViewType VirtualMachine
$arr_vm_list_simple = $var_cluster | Get-Vm 

#endregion setup


#region style

$a = ""

$a = $a + '

<style>


BODY{
	background-color:#fff; 
	font-family: verdana; 
	font-size:10px;
	color:#565b5c;
	}
TABLE{	
	border-collapse: collapse;
	text-align: center;
	border-left: 4px solid #ccdcff;
	
	}
TH{	
	padding: 12px;	
	font-weight: 620;
	}
TD{
	padding: 6px;	
	}
tr{
	background: #f2f7ff;
	}

h1 {
    background-color: #f2f7ff;
    color: #444;
    padding-top: 20px;
    padding-bottom: 20px;
    padding-left: 6px;
    width: 100%;
    border: none;
    text-align: left;
    outline: none;
    font-size: 24px;
}

button.accordion {
    background-color: #f2f7ff;
    color: #444;
    cursor: pointer;
    padding: 10px;
    width: 100%;
    border: none;
    text-align: left;
    outline: none;
    font-size: 12px;
    transition: 0.2s;
}

button.accordion.active, button.accordion:hover {
    background-color: #ccdcff;
}

button.accordion:after {
    content: "\02795";
    font-size: 13px;
    color: #777;
    float: right;
    margin-left: 5px;
    }

button.accordion.active:after {
    content: "\2796";
    }

div.panel {
    padding: 0 18px;
    background-color: white;
    max-height: 0;
    overflow: hidden;
    transition: 0.6s ease-in-out;
    opacity: 0;
    }

div.panel.show {
    opacity: 1;
    max-height: 1000000px;
    }


table.red{
	width:360px;
	}
	
table.red th{
	text-align:center; 
    vertical-align:middle;
	width:120px;
	}	
	
table.red tr{
	background: #ffecec;
    border-left: 4px solid #ff9999;	
	}	
	
	
table.green{
	width:360px;
	}

table.green th{
	text-align:center; 
    vertical-align:middle;
	width:120px;
	}

table.green tr{
	background: #ecfff5;
    border-left: 4px solid #b3ffd7;	
	}


</style>
'



$b = ""
#endregion style


#region module

# load all modules in the following directory path:

$module_path = "C:\Scripts\MMU vCheck\modules"
Get-ChildItem $module_path | Get-ChildItem | ForEach-Object {. (Join-Path $_.Directory $_.Name)} | Out-Null

#endregion modules


#region report


$b += '<h1>MMU vCheck</h1>'



# Cluster
#region cluster overview

$arr_cluster_health = fun_cluster_health -var_cluster $var_cluster


$b += "<p>"
$b += fun_add_cluster_html -value $arr_cluster_health.var_host_cpu -total $arr_cluster_health.var_host_cpu_total -label "Cluster CPU Usage" -limit 50
$b += fun_add_cluster_html -value $arr_cluster_health.var_host_memory -total $arr_cluster_health.var_host_memory_total -label "Cluster Memory Usage" -limit 50
$b += fun_add_cluster_html -value $arr_cluster_health.var_vm_cpu_count -total $arr_cluster_health.var_host_cpu_count -label "CPU Cores Allocated" -limit 100
$b += fun_add_drs_html -enabled $arr_cluster_health.var_drs_enabled -level $arr_cluster_health.var_drs_automation_level
$b += "</p>"
    
#endregion cluster overview




# vms


$b += '<button class="accordion">VM</button>'
$b += '<div class="panel">'

$arr_vm_memory_balloon = fun_vm_memory_balloon -arr_vm_list $arr_vm_list
$arr_vm_memory_balloon = $arr_vm_memory_balloon | Sort-Object "VM"
$b += fun_add_html -html_array $arr_vm_memory_balloon -html_title "Memory Ballooning"

$arr_vm_iops = fun_vm_iops -arr_vm_list $arr_vm_list_simple
$arr_vm_iops = $arr_vm_iops | Sort-Object "IOPSMax"
$b += fun_add_html -html_array $arr_vm_iops -html_title "VMs with IOPS above 100"

$arr_fun_vm_snapshots = fun_vm_snapshots -arr_vm_list $arr_vm_list
$arr_fun_vm_snapshots = $arr_fun_vm_snapshots | Sort-Object "VM"
$b += fun_add_html -html_array $arr_fun_vm_snapshots -html_title "VMs with old snapshots"

$arr_fun_vm_conslodation = fun_vm_consolodation -arr_vm_list $arr_vm_list_simple
$arr_fun_vm_conslodation = $arr_fun_vm_conslodation | Sort-Object "VM"
$b += fun_add_html -html_array $arr_fun_vm_conslodation -html_title "Need Consoldation"

$arr_vm_powered_off = fun_vm_powered_off -arr_vm_list $arr_vm_list
$arr_vm_powered_off = $arr_vm_powered_off | Sort-Object "Name"
$b += fun_add_html -html_array $arr_vm_powered_off -html_title "Powered Off VMs"

$arr_vm_notes = fun_vm_notes -arr_vm_list $arr_vm_list_simple
$arr_vm_notes = $arr_vm_notes | Sort-Object "Name"
$b += fun_add_html -html_array $arr_vm_notes -html_title "VMs with bad notes"

$arr_vm_bus_sharing_mode = fun_vm_bus_sharing_mode -arr_vm_list $arr_vm_list_simple
$arr_vm_bus_sharing_mode = $arr_vm_bus_sharing_mode | Sort-Object "Name"
$b += fun_add_html -html_array $arr_vm_bus_sharing_mode -html_title "VMs with Virtual SCSI BUS Sharing"

$b += '</div>'





# storage


$b += '<button class="accordion">Storage</button>'
$b += '<div class="panel">'

$arr_datastore_space = fun_datastore_space
$b += fun_add_html -html_array $arr_datastore_space -html_title "Datastore Space"

$b += '</div>'




# networking


$b += '<button class="accordion">Network</button>'
$b += '<div class="panel">'

$arr_nsx_lazy_rules = fun_nsx_lazy_rules
$b += fun_add_html -html_array $arr_nsx_lazy_rules -html_title "VMs in Firefighting"


$b += '</div>'




$b += '</div>'

$b += '
<script>
/* Toggle between adding and removing the "active" and "show" classes when the user clicks on one of the "Section" buttons. The "active" class is used to add a background color to the current button when its belonging panel is open. The "show" class is used to open the specific accordion panel */
var acc = document.getElementsByClassName("accordion");
var i;

for (i = 0; i < acc.length; i++) {
    acc[i].onclick = function(){
        this.classList.toggle("active");
        this.nextElementSibling.classList.toggle("show");
    }
}
</script>
'

$file = "C:\andy\output\mmu_vcheck.html"

$file

ConvertTo-HTML -head $a -Body $b -Title "MMU vCheck" | Out-File $file

Invoke-Item $file

#endregion report


#region send_mail

$date = Get-Date -format "yyyy-MM-dd"

$to = "a.mcshane@mmu.ac.uk"
$message = @()
$message += "MMU vCheck"
$message += "Generated on $date by $env:computername"


fun_send_mail -to $to -message $message -attachment $file


#endregion send_mail




