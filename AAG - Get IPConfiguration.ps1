﻿param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-xxxx-prod",

        [Parameter(Mandatory = $false)]
	    [String]$appGwName = "integ-shared-appgw-xxxx-dev-aes"
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
$backEndAddressPool = Get-AzureRmApplicationGatewayIPConfiguration -ApplicationGateway $AppGw # -Name $probeName
$backEndAddressPool



