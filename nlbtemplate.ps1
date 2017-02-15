<# Stop-NlbClusterNode
NAME

    Stop-NlbClusterNode
    
SYNOPSIS

    Stops a node in a Network Load Balancing (NLB) cluster.
    
SYNTAX

    Stop-NlbClusterNode [[-HostName] <String>] [-Drain] [-InterfaceName <String>] 
    [-Timeout <UInt32>] [<CommonParameters>]
    
    Stop-NlbClusterNode [-Drain] [-Timeout <UInt32>] -InputObject <Node[]> 
    [<CommonParameters>]
    
    
DESCRIPTION

    The Stop-NlbClusterNode cmdlet stops a node in a Network Load Balancing (NLB) 
    cluster. When the nodes are stopped in the cluster, client connections that are 
    already in progress are interrupted. To avoid interrupting active connections, 
    consider using the Drain parameter, which allows the node to continue servicing 
    active connections but disables all new traffic to that node.
    

PARAMETERS

    -Drain [<SwitchParameter>]
        Drains existing traffic before stopping the cluster node. If this parameter is 
        omitted, then the existing traffic will be dropped.
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -HostName <String>
        Specifies the name of the cluster host against which this cmdlet is run. If 
        this parameter is omitted or a value of . is entered, then the local cluster 
 #>

 
 
#I mport csv of 8 servers = $servers
 

