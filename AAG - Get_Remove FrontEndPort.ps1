param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-xxxx-dev",

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

$port = Get-AzureRmApplicationGatewayFrontendPort -ApplicationGateway $AppGw -Name 'newport2'
$port

Remove-AzureRmApplicationGatewayFrontendPort -Name $port.Name -ApplicationGateway $AppGw

$listener = Get-AzureRmApplicationGatewayHttpListener -Name 'apiaud.xxxx.com' -ApplicationGateway $AppGw 

$listener = Remove-AzureRmApplicationGatewayHttpListener -Name 'NewListener' -ApplicationGateway $AppGw -Verbose


Set-AzureRmApplicationGateway -ApplicationGateway $AppGw 



