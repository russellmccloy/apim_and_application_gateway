# Script can be called manually or via an Octopus Step template.
# It parameters are not supplied they will be populated from Octopus Parameters

# It will assume the Azure Authentication is already handled by Octopus and the context is
# for the correct subscription

param (
    [string] $resourceGroupName = $OctopusParameters["ResourceGroupName"],
	[string] $apiManagementInstance = $OctopusParameters["ApiManagementInstance"]
)

Write-Host "ResourceGroupName: $resourceGroupName"
Write-Host "ApiManagementInstance: $apiManagementInstance"

$ErrorActionPreference = "Stop"

function GenerateGitPassword
{
	param ([string] $id,[string] $key)
	$enc = [system.Text.Encoding]::UTF8
	$time = (Get-Date).ToUniversalTime().Date.AddDays(1)
	$keyEncoded = $enc.GetBytes($key)
	$hmacsha = new-object System.Security.Cryptography.HMACSHA512
	$hmacsha.Key = $keyEncoded
	$timeFormatted = $time.ToString("O")
	$s = "$id`n$timeFormatted"
	$bytes = $enc.GetBytes($s);
	$hash = $hmacsha.ComputeHash($bytes);
	$str2 = [System.Convert]::ToBase64String($hash)
	$plain = [System.String]::Format("uid={0}&ex={1:o}&sn={2}", $id, $time, $str2)
	Add-Type -AssemblyName System.Web 
	return [System.Web.HttpUtility]::UrlEncode($plain)	 
}

# =================================================================
# START - Get Crowns APIM code from on prem TFS
# =================================================================
$tempFolder = "Temp-$apiManagementInstance"

if(Test-Path $tempFolder)
{
	Remove-Item $tempFolder -Force -Recurse
}

$ErrorActionPreference = "Continue"   

Write-Host "Cloning Git Repository"
git config --global user.email "RussellDavid.McCloy@xxxx.com.au"   # THIS IS VERY BAD
git config --global user.name "xxxx"                                     # THIS IS VERY BAD

git config --global push.default simple   # Push only the current branch
git config --global core.autocrlf false   # Formatting-and-Whitespace - https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration#Formatting-and-Whitespace  

git clone -q "http://msd-tfs-01:8080/tfs/xxx/_git/Azure%20API%20Management" $tempFolder     # parameterise this: Azure%20API%20Management
    
Write-Host "Changing to folder $tempFolder"
cd $tempFolder

Write-Host "Doing a git pull"

git pull -q

# =================================================================
# END - Get Crowns APIM code from on prem TFS
# =================================================================


# =================================================================
# START - Push Crowns APIM code to the sesignated APIM instance
# =================================================================

Write-Host "Getting API Management Context for Service $apiManagementInstance in resource group $resourceGroupName"
$context = New-AzureRmApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apiManagementInstance

Write-Host "Enabling Git Access"
Set-AzureRmApiManagementTenantAccess -Context $context -Enabled $true     # USED TO BE: Set-AzureRmApiManagementTenantGitAccess

#Write-Host "Saving API Management to Git Configuration"
#Save-AzureRmApiManagementTenantGitConfiguration -Context $context -Force -Branch "master"

$gitAccessDetails = Get-AzureRmApiManagementTenantGitAccess -Context $context
$gitPassword = GenerateGitPassword $gitAccessDetails.Id $gitAccessDetails.PrimaryKey

Write-Host "Pushing to APIM destination"

git config branch.master.remote origin

git remote set-url origin "https://apim:$gitPassword@$apiManagementInstance.scm.azure-api.net"

git push -u origin master


# change back to root
cd ..

Write-Host "Publishing git repo to API Management"

$ErrorActionPreference = "Stop"

Publish-AzureRmApiManagementTenantGitConfiguration -Context $context -Force -Branch "master"
# =================================================================
# END - Push Crowns APIM code to the sesignated APIM instance
# =================================================================


