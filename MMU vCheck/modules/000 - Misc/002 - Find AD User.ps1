# matches up the name with the MMUID from AD, for finding who took snapshots
function fun_find_ad_user{
param($username)

    if ($username -ne $null -and $username -ne "Administrator")
    {
        $usr = (($username.split("\"))[1])
        $root = [ADSI]""
        $filter = ("(&(objectCategory=user)(samAccountName=$Usr))")
        $ds = new-object system.DirectoryServices.DirectorySearcher($root,$filter)
        $ds.PageSize = 1000
        $ds.FindOne()
    }
}