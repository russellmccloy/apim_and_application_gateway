﻿param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-xxxx-dev",

        [Parameter(Mandatory = $false)]
	    [String]$appGwName = "integ-shared-appgw-xxxx-dev-aes"

)

. "D:\MyDropbox\Dropbox (Personal)\My Documents\Technical - Azure Code Etc\General Powershell\Azure\login_to_azure.ps1"

Get-AzureRmApplicationGatewayBackendHealth -Name $appGwName -ResourceGroupName $resourceGroupName

$BackendHealth = Get-AzureRmApplicationGatewayBackendHealth -Name $appGwName -ResourceGroupName $resourceGroupName `
-ExpandResource "backendhealth/applicationgatewayresource"