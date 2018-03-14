﻿param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-xxxx-tst",

        [Parameter(Mandatory = $false)]
	    [String]$appGwName = "integ-shared-appgw-xxxx-tst-aes"

)

function Check-Session () {
    $Error.Clear()

    #if context already exist
    Get-AzureRmContext -ErrorAction Continue
    foreach ($eacherror in $Error) {
        if ($eacherror.Exception.ToString() -like "*Run Login-AzureRmAccount to login.*") {
            Login-AzureRmAccount
        }
    }

    $Error.Clear();
}

# call it here
Check-Session


$AppGw = Get-AzureRmApplicationGateway -Name $appGwName -ResourceGroupName $resourceGroupName

$listener = Get-AzureRmApplicationGatewayHttpListener -Name 'appGatewayHttpListener' -ApplicationGateway $AppGw 
$listener
#$listener = Remove-AzureRmApplicationGatewayHttpListener -Name 'apiaud.xxxx.comHTTP' -ApplicationGateway $AppGw -Verbose


#Set-AzureRmApplicationGateway -ApplicationGateway $AppGw 

# ==================================================================================================================================

#$AppGw = Get-AzureRmApplicationGateway -Name $appGwName -ResourceGroupName $resourceGroupName

#$listener = Get-AzureRmApplicationGatewayHttpListener -Name 'multiSiteListener' -ApplicationGateway $AppGw 

#$listener = Remove-AzureRmApplicationGatewayHttpListener -Name 'multiSiteListener' -ApplicationGateway $AppGw -Verbose

#Set-AzureRmApplicationGateway -ApplicationGateway $AppGw 






