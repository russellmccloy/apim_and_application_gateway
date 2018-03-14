param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-xxxx-dev",

        [Parameter(Mandatory = $false)]
	    [String]$apimName = "integ-shared-apim-xxxx-dev-aes",

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

# "apim-Generic-RG"
# "ContosoApi"

Check-Session


$apim = Get-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Name $apimName
Write-Host $apim[0].StaticIPs[0]

$AppGw = Get-AzureRmApplicationGateway -Name $appGwName -ResourceGroupName $resourceGroupName


$apimProxyBackendPool = Get-AzureRmApplicationGatewayBackendAddressPool -Name "appGatewayBackendPool" -ApplicationGateway $AppGw
$apimProxyBackendPool

$apimPoolSetting = Get-AzureRmApplicationGatewayBackendHttpSettings -Name "appGatewayBackendHttpSettings" -ApplicationGateway $AppGw
$apimPoolSetting

$echoapiRule = New-AzureRmApplicationGatewayPathRuleConfig -Name "allowEcho" -Paths "/echo/*" -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolSetting

$urlPathMap = New-AzureRmApplicationGatewayUrlPathMapConfig -Name "urlpathmap" -PathRules $echoapiRule -DefaultBackendAddressPool $apimProxyBackendPool -DefaultBackendHttpSettings $apimPoolSetting

$listener = Get-AzureRmApplicationGatewayHttpListener -Name 'apiaud.bluescope.com' -ApplicationGateway $AppGw 
$listener

$rule01 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "allowEchoRule" -RuleType PathBasedRouting -HttpListener $listener -UrlPathMap $urlPathMap

Set-AzureRmApplicationGateway -ApplicationGateway $AppGw 