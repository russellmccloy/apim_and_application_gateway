param
(
        [Parameter(Mandatory = $false)]
	    [String]$resourceGroupName = "integ-shared-rg01-xxxx-dev",

        [Parameter(Mandatory = $false)]
	    [String]$appGwName = "integ-shared-appgw-xxxx-dev-aes",

        [Parameter(Mandatory = $false)]
	    [int]$Timeout = 100
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

cls

$timeout = new-timespan -Minutes $Timeout
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout){

     
        $AppGw = Get-AzureRmApplicationGateway -Name $AppGWName -ResourceGroupName $resourceGroupName

     #$apim;
     if($AppGw.ProvisioningState -ne "Updating")
     {
        return;
     } else {
        ""
     }
     $AppGw.ProvisioningState + "...";
     start-sleep -seconds 5
}
 
write-host "Completed"

