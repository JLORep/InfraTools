$Today = (Get-Date -Format "yyyyMMdd-HH.mm")

$defaultVIServer = "vc2.ad.mmu.ac.uk"

$vcenterServer = $defaultVIServers



# PowerCLI Header
Write-host "Loading PowerCLI" -ForeGroundColor Red
$VMwareLoaded = $(Get-PSSnapin | ? {$_.Name -like "*VMware*"} ) -ne $null
If ($VMwareLoaded) { }
Else
{
Add-PSSnapin -Name "VMware.VimAutomation.Core" | Out-Null
}

# Connect vCenter Server
Write-host "Connecting vCenter" -ForeGroundColor Yellow
Connect-VIserver -server $vCenterServer | Out-Null

function Export-VM
{
    param
    (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)] $vm,
        [parameter(Mandatory=$true)][String] $destination
    )
 
    $ovftoolpaths = ("C:\Program Files (x86)\VMware\VMware OVF Tool\ovftool.exe","C:\Program Files\VMware\VMware OVF Tool\ovftool.exe")
    $ovftool = ''
 
    foreach ($ovftoolpath in $ovftoolpaths)
    {
        if(test-path $ovftoolpath)
        {
            $ovftool = $ovftoolpath
        }
    }
    if (!$ovftool)
    {
        write-host -ForegroundColor red "ERROR: OVFtool not found in it's standard path."
        write-host -ForegroundColor red "Edit the path variable or download ovftool here: http://www.vmware.com/support/developer/ovf/"
    }
    else
    {
        $moref = $vm.extensiondata.moref.value
        $session = Get-View -Id SessionManager
        $ticket = $session.AcquireCloneTicket()
        & $ovftool "--I:sourceSessionTicket=$($ticket)" "vi://$($defaultviserver.name)?moref=vim.VirtualMachine:$($moref)" "$($destination)$($vm.name).ovf"
    }
}