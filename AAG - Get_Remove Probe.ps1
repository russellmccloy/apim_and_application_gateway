 param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-xxxx-dev",

        [Parameter(Mandatory = $false)]
	    [String]$appGwName = "integ-shared-appgw-xxxx-dev-aes",

        [Parameter(Mandatory = $false)]
	    [String]$probeName = "APIM_HTTP"
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
$probe = Get-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $AppGw -Name $probeName
$probe

# OPTIONAL REMOVE
$probe = Remove-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $AppGw -Name $probeName

#Set-AzureRmApplicationGateway -ApplicationGateway $AppGw 
