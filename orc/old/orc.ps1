
########################################
#                                      #
#                 ORC                  #
#    Servers & Storage Orchestrator    #
#                                      #
########################################


#region credentials


    # Sharepoint Creds
    $sp_user = "PSPICFARM"
    $sp_pass = "7Bt#9@cUaJXYW5rL"

    $sp_sec_pass = $sp_pass | ConvertTo-SecureString -AsPlainText -Force 

    $sp_credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sp_user, $sp_sec_pass



#endregion credentials

#region pull_data_from_sharepoint




#  hmm - we need validation here that checks if the VM has been built
# best way would be to do check the vcenter every time the script is called, if the servers that are listed as pending have been created, they are set to complete before any build work is started


#create a session that allows you to to use powershell 2.0 and double-pass your credentials with credssp
$sp_session = New-PSSession pspicapp01 -ConfigurationName PS2 -authentication credssp -credential $sp_credential

# in that session, grab the info from the sharepoint list and return any objects that are still set to 'Pending'
$pending_builds = Invoke-Command -Session $sp_session -ScriptBlock {

    # add the shareppint functions to powershell
    if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )
    { 
       Add-PsSnapin Microsoft.SharePoint.PowerShell 
    }

    # connect to the correct sharepoint url
    $sharepoint_url = Get-SPWeb "https://icred.mmu.ac.uk/its/ServersStorage"

    # connect to the correct sharepoint list for the orc_list
    $orc_list = $sharepoint_url.Lists["Server Build"]

    # create an array that will be populated with vms that need building
    $pending_builds = @()

    # loop through each item in the sharepoint list and create a powershell object so it can be manipulated easily in powershell
    $orc_items = $orc_list.Items
    foreach ($orc_item in $orc_items){

        $build_object = New-Object –TypeName PSObject
    
        $build_object | Add-Member –MemberType NoteProperty –Name Service –Value $orc_item["Name - Service"]
        $build_object | Add-Member –MemberType NoteProperty –Name Role –Value $orc_item["Name - Role"]
        $build_object | Add-Member –MemberType NoteProperty –Name Node –Value $orc_item["Name - Node"]
        $build_object | Add-Member –MemberType NoteProperty –Name OS –Value $orc_item["OS"]
        $build_object | Add-Member –MemberType NoteProperty –Name DC –Value $orc_item["Datacentre Cluster"]
        $build_object | Add-Member –MemberType NoteProperty –Name IPAddress –Value $orc_item["IPAddress"]
        $build_object | Add-Member –MemberType NoteProperty –Name Subnet –Value $orc_item["Subnet"]
        $build_object | Add-Member –MemberType NoteProperty –Name Gateway –Value $orc_item["Gateway"]
        $build_object | Add-Member –MemberType NoteProperty –Name CPU –Value $orc_item["CPU"]
        $build_object | Add-Member –MemberType NoteProperty –Name Memory –Value $orc_item["Memory"]
        $build_object | Add-Member –MemberType NoteProperty –Name Status –Value $orc_item["Status"]
        $build_object | Add-Member –MemberType NoteProperty –Name SupportContact –Value $orc_item["Support Contact"]
        $build_object | Add-Member –MemberType NoteProperty –Name Description –Value $orc_item["Description"]

        # result of $orc_item["Service Owner"] is "509;#Andrew McShane", so use the PS split function to make pretty
        $str_service_owner = $orc_item["Service Owner"] -split "#"
        $build_object | Add-Member –MemberType NoteProperty –Name ServiceOwner –Value $str_service_owner[1]
        
        # result of $orc_item["Application Owner"] is "509;#Andrew McShane", so use the PS split function to make pretty
        $str_application_owner = $orc_item["Application Owner"] -split "#"
        $build_object | Add-Member –MemberType NoteProperty –Name ApplicationOwner –Value $str_application_owner[1]

        # result of $orc_item["NSX Network"] is "109;#Network Name", so use the PS split function to make pretty
        $str_nsx_network = $orc_item["NSX Network"] -split "#"
        $build_object | Add-Member –MemberType NoteProperty –Name NSXNetwork –Value $str_nsx_network[1]
        
        # create the name of the server from the individual parts
        $build_object_name = $build_object.Service + "-" + $build_object.Role + "-" + $build_object.Node
        $build_object_name = $build_object_name.toupper()
        $build_object | Add-Member –MemberType NoteProperty –Name Name –Value $build_object_name

        # add a value for when the server was built
        $date_now = Get-Date -format "dd/MMM/yyyy"
        $build_object | Add-Member –MemberType NoteProperty –Name BuildDate –Value $date_now


        # check if the object is pending build, if so, take action
        if ($build_object.Status -eq "Pending")
        {
            # add the build object to the array that will be used to provision servers
            $pending_builds += $build_object

        }

    } 

    return $pending_builds

}

# clean up after yourself by closing the sessions
Remove-PSSession -ID $sp_session.ID

# clean up even firther by calling the garbage collector and cleaning up both the sessions you have created and the objects
# this will ensure you don't get memory leaks
[GC]::Collect()

# return the array of objects pending creation
$pending_builds


#endregion pull_data_from_sharepoint

#region vm_build





# specify how many threads the process can run concurrently
$max_threads = 10


ForEach ($build in $pending_builds){
    # check to see if there are too many open threads
    # if there are too many threads then wait here until some close
    # script will check every 10 seconds to see if slots are free for a thread to be created
    
    $output_to_file = @()
    $output_to_file += ""
    $output_to_file += ""
    $output_to_file += $build.Name
    $output_to_file += ""

    $output_to_file | out-file -FilePath "C:\Scripts\orc\output.txt" -Append 
    $build | out-file -FilePath "C:\Scripts\orc\output.txt" -Append

    # one of the following three 
    
    # possible 1
    # Start-Job -FilePath $ScriptFile -ArgumentList $build
    
    # possible 2
    # Start-Job -ScriptBlock { C:\csv\JobTest.ps1 $args[0] $args[1] } -ArgumentList @($foo, $bar)

    # possible 3 - will probably work but would like to keep it all in one place
    # Start-Job -ScriptBlock { C:\csv\serverbuild.ps1 $args[0]} -ArgumentList @($build)

    # possible 4
    # multithread the applicaiton


    




    # add an event to the log to note when a server has been picked up by the orchestrator
    $log_message = @()
    $log_message += $build.Name + " found in sharepoint with the status Pending"
    $log_message += "loaded into orchestrator"
    $log_message += "VM build started"
    Write-EventLog -LogName "ORC" -ComputerName informer -Source "ORC" -EventID 100 -EntryType Information -Message $($log_message -join [Environment]::NewLine)


        

    # load in the vmware powershell module
    if(!(Get-module VMware.VimAutomation.Core)){Import-Module VMware.VimAutomation.Core}

    # specify vcenter
    $vcenter = "auron.ad.mmu.ac.uk"

    # log into vcenter
    connect-viserver -server $vcenter

    # check if the VM already exists before trying to build another
    $check_vm = Get-vm -Name $build.Name
    if (!$check_vm) {


#region calculated_build_variables

        # get the cluster name to feed into the datastore calculation
        $vm_cluster = $build.DC
        if($vm_cluster -eq "NSX"){$vm_cluster = "Gold"}
        
        # get the host with the most free resoures in the specified cluster to place the new vm on    
        $stats = Get-Stat -Entity (Get-cluster $vm_cluster | Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}) -Stat "mem.usage.average" -Realtime -MaxSamples 1
        $avg = $stats | Measure-Object -Property Value -Average | Select -ExpandProperty Average
        $chosen_host = $stats | where{$_.Value -lt $avg} | Get-Random | Select -ExpandProperty Entity
        
        # select the datastore based on the datastore with the most space free in the Pre-NSX cluster
        $vm_datastore = get-cluster $vm_cluster | get-vmhost | get-datastore | Where-Object { $_.Name -like '*Gold*' -and $_.FreeSpaceGB -gt 250} | Sort-Object -Property FreespaceGB -Descending:$true | Select-Object -First 1
        $alt_vm_datastore = $chosen_host | get-datastore | Where-Object { $_.Name -like '*Gold*' -and $_.FreeSpaceGB -gt 250} | Sort-Object -Property FreespaceGB -Descending:$true | Select-Object -First 1
        


        # specify the MMU DNS servers
        $dns1 = "149.170.39.93"
        $dns2 = "149.170.39.92"
        
        # work out which template to use based on the DC field (NSX or not) and the OS chosen
        $vm_template = ""
        $customisation_spec = ""
        
        if ($build.DC -eq "NSX" -and $build.OS -eq "CentOS 7"){$vm_template = "NSX CentOS 7"; $customisation_spec = "LinuxStd"}
        if ($build.DC -eq "NSX" -and $build.OS -eq "Windows Server 2008 R2"){$vm_template = "NSX Windows Server 2008 R2"; $customisation_spec = "Windows2008Std"}
        if ($build.DC -eq "NSX" -and $build.OS -eq "Windows Server 2012 R2"){$vm_template = "NSX Windows Server 2012 R2"; $customisation_spec = "Windows2012Std"}
        if ($build.DC -eq "Pre-NSX" -and $build.OS -eq "CentOS 7"){$vm_template = "Pre-NSX CentOS 7"; $customisation_spec = "LinuxStd"}
        if ($build.DC -eq "Pre-NSX" -and $build.OS -eq "Windows Server 2008 R2"){$vm_template = "Pre-NSX Windows Server 2008 R2"; $customisation_spec = "Windows2008Std"}
        if ($build.DC -eq "Pre-NSX" -and $build.OS -eq "Windows Server 2012 R2"){$vm_template = "Pre-NSX Windows Server 2012 R2"; $customisation_spec = "Windows2012Std"}



        # here is where we will keep track of the failure state
        $build_status
        

        # select the network
        $vm_network = $build.NSXNetwork
        if ($build.DC -eq "Pre-NSX"){
            $vm_network = "Server Private"
            $ip_first_bit = $build.IPAddress.Substring(0,2) 
            if ($ip_first_bit -eq "14"){$vm_network = "Server Public"}
        }

        


        # add an event to the log to note when a server has been picked up by the orchestrator
        $notes = @()
        $notes += "Name: " + $build.Name        
        $notes += ""        
        $notes += "Created by ORC - Servers & Storage Orchestrator"
        $notes += ""  
        $notes += "Creation Date: " + $build.BuildDate 
        $notes += ""       
        $notes += "OS: " + $build.OS
        $notes += "IPAddress: " + $build.IPAddress
        $notes += "Subnet: " + $build.Subnet
        $notes += "Gateway: " + $build.Gateway
        $notes += ""
        $notes += "Service Owner:      " + $build.ServiceOwner
        $notes += "Application Owner:  " + $build.ApplicationOwner
        $notes += "Support Contact:    " + $build.SupportContact
        $notes += ""
        $notes += "Description"
        $notes += $build.Description



            




#endregion calculated_build_variables

#region build_logic

        if($build.OS -eq "CentOS 7"){
            #Configure the Customization Spec info
            Get-OSCustomizationSpec $customisation_spec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $build.IPAddress -SubnetMask $build.Subnet -DefaultGateway $build.Gateway
        }else{
            #Configure the Customization Spec info
            Get-OSCustomizationSpec $customisation_spec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $build.IPAddress -SubnetMask $build.Subnet -DefaultGateway $build.Gateway -Dns $dns1,$dns2
        }
        


        $build_error = ""
        

        # 1st stage - build vm with the basic information
        Clear-Variable -Name build_error
        New-VM -Name $build.Name -Template $vm_template -Datastore $alt_vm_datastore -DiskStorageFormat "Thick" -VMHost $chosen_host | Set-VM -OSCustomizationSpec $customisation_spec -Confirm:$false -ErrorVariable build_error        
        
        $log_message = @()
        $log_message += $vm_name
        $log_message += "Stage 1"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 101 -EntryType Information -Message $($log_message -join [Environment]::NewLine)        
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 101 -EntryType Error -Message $($build_error -join [Environment]::NewLine)

        }


        # 2nd stage - move vm to the new folder
        Clear-Variable -Name build_error
        Get-vm -Name $build.Name | move-vm -Destination $(Get-Folder -Name "New" -Location "Pre-NSX") -ErrorVariable build_error
        
        
        $log_message = @()
        $log_message += $vm_name
        $log_message += "Stage 2"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 102 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 102 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 3rd stage - set networking
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vm_network -Confirm:$false -ErrorVariable build_error
        
        
        $log_message = @()
        $log_message += $vm_name
        $log_message += "Stage 3"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 103 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 103 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 4th stage - set CPU and RAM
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Set-VM -MemoryGB $build.Memory -NumCpu $build.CPU -Confirm:$false -ErrorVariable build_error
        
        
        $log_message = @()
        $log_message += $vm_name
        $log_message += "Stage 4"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 104 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 104 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 5th stage - add noted to vm
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Set-VM -Description $($notes -join [Environment]::NewLine) -Confirm:$false -ErrorVariable build_error
               
        $log_message = @()
        $log_message += $vm_name
        $log_message += "Stage 5"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 105 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 105 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 6th stage - power on
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Start-VM -Confirm:$false -ErrorVariable build_error
        
        $log_message = @()
        $log_message += $vm_name
        $log_message += "Stage 6"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 106 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 106 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }

#endregion build_logic
        


    }

    
} 




#endregion vm_build



#region check_vm_build


#foreach build that is still pending, check if built and set the status in sharepoint accordingly
ForEach ($build in $pending_builds){
    
    $check_vm = Get-vm -Name $build.Name


    if ($check_vm) {
                
        #create a session that allows you to to use powershell 2.0 and double-pass your credentials with credssp
        $sp_session = New-PSSession pspicapp01 -ConfigurationName PS2 -authentication credssp -credential $sp_credential

        # in that session, grab the info from the sharepoint list and return any objects that are still set to 'Pending'
        Invoke-Command -Session $sp_session -args $build -ScriptBlock {

        # pull the IP address out of the argument list
        $ip = $args | select IPAddress

            # add the shareppint functions to powershell
            if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )
            { 
               Add-PsSnapin Microsoft.SharePoint.PowerShell 
            }

            # connect to the correct sharepoint url
            $sharepoint_url = Get-SPWeb "https://icred.mmu.ac.uk/its/ServersStorage"
            

            # connect to the correct sharepoint list for the orc_list
            $orc_list = $sharepoint_url.Lists["Server Build"]
            

            # loop through each item in the sharepoint list and create a powershell object so it can be manipulated easily in powershell
            $orc_items = $orc_list.Items
            

            foreach ($orc_item in $orc_items){

                # the IP of the server is the only truly unique value, so this is what we will choose
                if($orc_item["IPAddress"] -eq $ip.IPAddress)
                {
                    # change the status to complete
                    $orc_item["Status"] = "Complete"
 
                    # update the item
                    $orc_item.Update()
                }

            } 

        }

        # clean up after yourself by closing the sessions
        Remove-PSSession -ID $sp_session.ID

        # clean up even firther by calling the garbage collector and cleaning up both the sessions you have created and the objects
        # this will ensure you don't get memory leaks
        [GC]::Collect()
       
    }


    #region solarwinds



    
    #region solarwindssnapins

    if (-not (Get-PSSnapin -Name "SwisSnapin" -ErrorAction SilentlyContinue))
    {    
        Add-PSSnapin SwisSnapin -ErrorAction SilentlyContinue
    }

    if (-not (Get-PSSnapin -Name "PowerOrion" -ErrorAction SilentlyContinue))
    {    
        Add-PSSnapin PowerOrion -ErrorAction SilentlyContinue
    }

    #endregion solarwindssnapins


    # this is an example
    $vm_os = "CentOS 7"

    #this will be updated by 
    $solarwinds_node_name = $build.Name

    $solarwinds_node_ip = [System.Net.Dns]::GetHostAddresses($solarwinds_node_name)
    $solarwinds_node_ip = $solarwinds_node_ip.IPAddressToString
    $solarwinds_node_ip 



    #region solarwinds_connection

    $solarwinds_server_hostname = "sssolarwinds"

    Write-Host "creating credential object"
    $solarwinds_server_user = "SSOrchestrator"
    $solarwinds_server_pass = "TwentySevenLampTable" | ConvertTo-SecureString -AsPlainText -Force
    $solarwinds_server_cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $solarwinds_server_user, $solarwinds_server_pass


    Write-Host "creating swis connection"
    $swis = Connect-Swis -host $solarwinds_server_hostname -Credential $solarwinds_server_cred

    Write-Host "getting data from swis connection"
    #Get-SwisData $swis 'SELECT NodeID, IP, Caption FROM Orion.Nodes'

    #endregion solarwinds_connection



    #region solarwinds_check_exists

    $solarwinds_node_check_name = "'" + $solarwinds_node_name + "'"
    $check_query = 'SELECT NodeID, IP, Caption FROM Orion.Nodes WHERE Caption=' + $solarwinds_node_check_name
    clear-variable -name solarwinds_check
    $solarwinds_check = Get-SwisData $swis $check_query
    $solarwinds_check

    if(!$solarwinds_check)
    {
        solarwinds_add_node -SWIS $swis -OS $vm_os -IP $solarwinds_node_ip -Hostname $solarwinds_node_name
    }
    else
    {
        Write-Host "VM already exists in monitoring"
    }

    #endregion solarwinds_check_exists


     function solarwinds_add_node
     {
      param(
      $SWIS,
      [string]$OS,
      [string]$IP,
      [string]$Hostname
      )
  
      Write-Output $SWIS
      Write-Output $OS
      Write-Output $IP
      Write-Output $Hostname


        # add a node
        $newNodeProps = @{
            IPAddress = $IP;
            EngineID = 1;
            Caption = $Hostname;
            ObjectSubType = "SNMP";
            SNMPVersion = 2;


            # SNMP v2 specific       

            # === default values ===

            # EntityType = 'Orion.Nodes'
        
            # DynamicIP = false
            # PollInterval = 120
            # RediscoveryInterval = 30
            # StatCollection = 10  
        }


        $newNodeUri = New-SwisObject $SWIS -EntityType "Orion.Nodes" -Properties $newNodeProps
        $nodeProps = Get-SwisObject $SWIS -Uri $newNodeUri

        # register specific pollers for the node
        $poller = @{
            NetObject="N:"+$nodeProps["NodeID"];
            NetObjectType="N";
            NetObjectID=$nodeProps["NodeID"];
        }

        # Status
        $poller["PollerType"]="N.Status.ICMP.Native";
        $pollerUri = New-SwisObject $SWIS -EntityType "Orion.Pollers" -Properties $poller

        # Response time
        $poller["PollerType"]="N.ResponseTime.ICMP.Native";
        $pollerUri = New-SwisObject $SWIS -EntityType "Orion.Pollers" -Properties $poller


     }


 #endregion solarwinds




    
}

#region check_vm_build


