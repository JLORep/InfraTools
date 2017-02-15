 import-module NetworkLoadBalancingClusters
    $RemoteHostName = "Yuki"
    $user = "ad\46020944" 
    $PWord = ConvertTo-SecureString -String "Pa55work" -AsPlainText -Force 
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord 
    Get-Credential $Credential

    #uses the nlb cmdlets to check the state of the current cluster 
    $clusterstatus = get-nlbclusternode -nodename $RemoteHostName

    [string]$status = $clusterstatus | select -expand state 
        #if the node has already been stopped dont do anything 
    if ($status -eq "Stopped") 
        { 
            #donothing 
            "Node already stopped" 
        }

        #if the node hasnt been stopped, stop the node 
    else 
        {

        "Starting to drain stop the node" 
           Write-Host "winnersssssssssssssssss"
            #stop-NlbClusterNode -HostName $RemoteHostName -Drain 
        }