
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
        $str_service_name = $orc_item["Name - Service"] -split "#"
        $build_object | Add-Member –MemberType NoteProperty –Name Service –Value $str_service_name[1]

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
        $date_now = (Get-Date).ToString('dd/MM/yyyy')
        $date_then = (Get-Date).AddYears(3).ToString('dd/MM/yyyy')
        
        $build_object | Add-Member –MemberType NoteProperty –Name BuildDate –Value $date_now.ToString()
        $build_object | Add-Member –MemberType NoteProperty –Name DecomDate –Value $date_then.ToString()


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





$scriptPath = "C:\Scripts\orc\orc-slave.ps1"


ForEach ($build in $pending_builds){

    # this is slow and single threaded
    Invoke-Expression "$scriptPath `$build"

    # hopefully quick and multithreaded
    #start-job -filepath $scriptPath -ArgumentList $build
    
    }
	
