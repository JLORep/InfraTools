
########################################
#                                      #
#                 ORC                  #
#    Servers & Storage Orchestrator    #
#                                      #
########################################


#region input_variables

$build=$args[0]

#endregion input_variables

#region credentials

    # Sharepoint Creds
    $sp_user = "PSPICFARM"
    $sp_pass = "7Bt#9@cUaJXYW5rL"

    $sp_sec_pass = $sp_pass | ConvertTo-SecureString -AsPlainText -Force 

    $sp_credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sp_user, $sp_sec_pass

#endregion credentials


    # split the script here, pass the build variable across and then build machines that way, that way we can multithread it
    

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
        
        if ($build.OS -eq "CentOS 7"){$vm_template = "NSX CentOS 7"; $customisation_spec = "LinuxStd"}
        if ($build.OS -eq "Windows Server 2008 R2"){$vm_template = "NSX Windows Server 2008 R2"; $customisation_spec = "Windows2008Std"}
        if ($build.OS -eq "Windows Server 2012 R2"){$vm_template = "NSX Windows Server 2012 R2"; $customisation_spec = "Windows2012NSX"}
        


        # here is where we will keep track of the failure state
        $build_status
        

        # select the network
        $vm_network = $build.NSXNetwork
         


        # create the notes th
        $notes = @()
        $notes += "Name: " + $build.Name        
        $notes += ""        
        $notes += "Created by ORC - Servers & Storage Orchestrator"
        $notes += ""  
        $notes += "Creation Date: " + $build.BuildDate 
        $notes += "Review Date: " + $build.DecomDate 
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
        $log_message += $build.Name
        $log_message += "Stage 1"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 101 -EntryType Information -Message $($log_message -join [Environment]::NewLine)        
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 101 -EntryType Error -Message $($build_error -join [Environment]::NewLine)

        }


        # 2nd stage - move vm to the new folder
        Clear-Variable -Name build_error
        Get-vm -Name $build.Name | move-vm -Destination $(Get-Folder -Name "New" -Location "Pre-NSX") -ErrorVariable build_error
        
        
        $log_message = @()
        $log_message += $build.Name
        $log_message += "Stage 2"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 102 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 102 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 3rd stage - set networking
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vm_network -Confirm:$false -StartConnected:$true -ErrorVariable build_error
        
        
        $log_message = @()
        $log_message += $build.Name
        $log_message += "Stage 3"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 103 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 103 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 4th stage - set CPU and RAM
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Set-VM -MemoryGB $build.Memory -NumCpu $build.CPU -Confirm:$false -ErrorVariable build_error
        
        
        $log_message = @()
        $log_message += $build.Name
        $log_message += "Stage 4"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 104 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 104 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 5th stage - add noted to vm
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Set-VM -Description $($notes -join [Environment]::NewLine) -Confirm:$false -ErrorVariable build_error
               
        $log_message = @()
        $log_message += $build.Name
        $log_message += "Stage 5"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 105 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 105 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }


        # 6th stage - power on
        Clear-Variable -Name build_error
        Get-VM -Name $build.Name | Start-VM -Confirm:$false -ErrorVariable build_error
        
        $log_message = @()
        $log_message += $build.Name
        $log_message += "Stage 6"
        Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 106 -EntryType Information -Message $($log_message -join [Environment]::NewLine)      
        if ($build_error) {
            Write-EventLog -LogName "ORC" -Source "ORC" -computername informer -EventID 106 -EntryType Error -Message $($build_error -join [Environment]::NewLine)
        }

#endregion build_logic
        


    }

    
 




#endregion vm_build



#region check_vm_build


    
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






#endregion check_vm_build


