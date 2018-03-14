 param
(
        [Parameter(Mandatory = $true)]
	    [String]$resourceGroup = "integ-shared-rg01-xxxx-dev",
  
        [Parameter(Mandatory = $true)]
	    [String]$appGateway = "integ-shared-appgw-xxxx-dev-aes",

        [Parameter(Mandatory = $true)]
	    [switch]$stop
)

. "D:\MyDropbox\Dropbox (Personal)\My Documents\Technical - Azure Code Etc\General Powershell\Azure\login_to_azure.ps1"


$getgw = Get-AzureRmApplicationGateway -Name $appGateway -ResourceGroupName $resourceGroup

if($stop) {
    Write-Host "STOPPING"
    Stop-AzureRmApplicationGateway -ApplicationGateway $getgw  
} else {
    Write-Host "STARTING"
    Start-AzureRmApplicationGateway -ApplicationGateway $getgw  
}

