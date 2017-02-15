# get any VM that has any value of ballooned memory or swapped memory over 100MB
function fun_nsx_lazy_rules{

    # define the scope of your NSX query
    $scope_id = "globalroot-0"
    $sec_name = "TEMP - FIREFIGHT"
    $nsx_ip = "10.110.100.9"

# ignore self signed SSLs on your NSX Manager
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    # get some sweet credentials
    $user = "SSOrchestrator"
    $pass = "TwentySevenLampTable"

    # encode it to the correct format to use REST Basic Auth 
    $pair = "${user}:${pass}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"
    $headers = @{ Authorization = $basicAuthValue }

    # define the URLs you will be querying>
    $edge_config_uri = "https://$nsx_ip/api/2.0/services/securitygroup/scope/$scope_id"


    # make your requests
    $config_request = Invoke-WebRequest -Uri $edge_config_uri -Headers $headers -Method GET

    # parse the xml
    [xml]$config_response = $config_request.Content

    # get the firefighting security group
    $sec_group = $config_response.ChildNodes.securitygroup | ? {$_.Name -eq $sec_name}

    # pull out the list of servers in firefighting and sort it to be alphabetical
    $servers_in_firefighting = $sec_group.member.name
    $servers_in_firefighting = $servers_in_firefighting | sort
    #$servers_in_firefighting

    $output_list = @()
    foreach($server in $servers_in_firefighting){

    $local_notes = get-vm $server

    $obj_local = New-Object –TypeName PSObject    
    $obj_local | Add-Member –MemberType NoteProperty –Name Name –Value $server
    $obj_local | Add-Member –MemberType NoteProperty –Name Notes –Value $local_notes.Notes
    $output_list += $obj_local


    }
    $output_list

}
