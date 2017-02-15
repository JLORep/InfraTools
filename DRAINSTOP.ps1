######################################################
# Name: NLB Drain Stop for SSS Farm [ExportOnly.ps1] #
# Desc: NLB Drain Stop for SSS Farm                  #
#                                                    #
######################################################
# Date: 07/07/2015                                   #
# Auth: jameseymail@hotmail.co.uk                    #
######################################################

import-module servermanager
add-windowsfeature nlb
import-module networkloadbalancingclusters
$nodes = get-nlbclusternode

####################
#  CHANGE 1:
####################
# Change the node name on this line to %ClusterName%:%Node2Name% so for example: "pubwebtest:pubwebtest02" 
Start-NewProcess "nlb.exe" 'drainstop pubwebtest:pubwebtest01' | out-file "C:\Users\user_account\desktop\drainstopout.txt"
 
####################
#  CHANGE 2:
####################
# Change the node name on this line to %ClusterName%:%Node2Name% so for example: "pubwebtest:pubwebtest02" 
Start-NewProcess "nlb.exe" 'start pubwebtest:pubwebtest01' | out-file "C:\Users\user_account\desktop\restartout.txt"
 
####################
#  CHANGE 3:
####################
# Either comment this line out at the end or replace it with an e-mail alert to let you 
# know the process has been completed successfully
& schtasks /run /S 'Node1' /NT 'HandOffToNode2'

NLB drainstop Cluster [: Host ]