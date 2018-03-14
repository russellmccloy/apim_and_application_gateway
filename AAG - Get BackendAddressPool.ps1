param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-bslau-dev",

        [Parameter(Mandatory = $false)]
	    [String]$appGwName = "integ-shared-appgw-bslau-dev-aes",

        [Parameter(Mandatory = $false)]
	    [String]$probeName = "apimproxyprobe"
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
$backEndAddressPool = Get-AzureRmApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw # -Name $probeName
$backEndAddressPool
