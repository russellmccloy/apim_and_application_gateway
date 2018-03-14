 param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroup = "integ-shared-rg01-bslau-dev",
  
        [Parameter(Mandatory = $false)]
	    [String]$appGateway = "integ-shared-appgw-bslau-dev-aes"
)

. "D:\MyDropbox\Dropbox (Personal)\My Documents\Technical - Azure Code Etc\General Powershell\Azure\login_to_azure.ps1"


$getgw = Get-AzureRmApplicationGateway -Name $appGateway -ResourceGroupName $resourceGroup

$getgw

