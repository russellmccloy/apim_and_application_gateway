param (
    [Parameter(Mandatory = $false)]
    [string] $resourceGroupName = "DEV",

    [Parameter(Mandatory = $false)]
    [string] $apiManagementInstance = "apimRussDev",

    [Parameter(Mandatory = $false)]
    [string] $vstsRepo = "https://russellmccloy.visualstudio.com/_git/DeployAPIMPractice"
    
)

cls

Write-Host "LOGGING IN"

#. "D:\MyDropbox\Dropbox (Personal)\My Documents\Technical - Azure Code Etc\General Powershell\Azure\login_to_azure.ps1"


Write-Host "ResourceGroupName: $resourceGroupName"
Write-Host "ApiManagementInstance: $apiManagementInstance"
Write-Host "vstsRepo: $vstsRepo"

$ErrorActionPreference = "Stop"

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

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


# change to the directory where THIS script is running as we want use use this for the tempFolder created below
$directory = Get-ScriptDirectory
Write-Host "Directory: $directory"
cd $directory;

# =================================================================
# START - Get APIM code from TFS
# =================================================================

try
{
    $tempFolder = "Temp-$apiManagementInstance"

    if(Test-Path $tempFolder)
    {
		Write-Host "Removing TEMP folder"
	    Remove-Item $tempFolder -Force -Recurse
    }
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}




Write-Host "Setting GIT credentials"
git config --global user.email "russell.mccloy@googlemail.com"   
git config --global user.name "Wombat22"                       

#git config --global push.default simple   # Push only the current branch
#git config --global core.autocrlf false   # Formatting-and-Whitespace - https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration#Formatting-and-Whitespace  

try
{
	Write-Host "Cloning Git Repository"
	git clone -q $vstsRepo "$directory\TEST" --verbose  
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}
    
#Write-Host "Changing to folder $tempFolder"
#cd $tempFolder

#Write-Host "Doing a git pull"

#git pull -q

try
{
	Write-Host "Getting API Management Context for Service $apiManagementInstance in resource group $resourceGroupName"
	$context = New-AzureRmApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apiManagementInstance
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

try
{
	Write-Host "Enabling Git Access"
	Set-AzureRmApiManagementTenantAccess -Context $context -Enabled $true     # USED TO BE: Set-AzureRmApiManagementTenantGitAccess
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}



#Write-Host "Saving API Management to Git Configuration"
#Save-AzureRmApiManagementTenantGitConfiguration -Context $context -Force -Branch "master"

try
{
	$gitAccessDetails = Get-AzureRmApiManagementTenantGitAccess -Context $context
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

Write-Host "gitAccessDetailsId: " $gitAccessDetails.Id
Write-Host "gitAccessDetailsPrimaryKey: " $gitAccessDetails.PrimaryKey

try
{
	$gitPassword = GenerateGitPassword $gitAccessDetails.Id $gitAccessDetails.PrimaryKey
	Write-Host "gitPassword: " $gitPassword
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

#git config branch.master.remote origin

#git remote set-url origin "https://apim:$gitPassword@$apiManagementInstance.scm.azure-api.net"

try
{
    cd "$directory\TEST";

	Write-Host "Adding remote called: $apiManagementInstance at https://$apiManagementInstance.scm.azure-api.net"

	git remote add $apiManagementInstance "https://$apiManagementInstance.scm.azure-api.net"
	git remote set-url $apiManagementInstance "https://apim:$gitPassword@$apiManagementInstance.scm.azure-api.net"
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

git remote -v
#git push -u apimRussDev master

try
{
	Write-Host "Pushing to remote $apiManagementInstance"
    git push -u $apiManagementInstance master # --all --verbose
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}


# change back to root
cd ..

try
{
	Write-Host "Publishing git repo to API Management"

	#$ErrorActionPreference = "Stop"

	Publish-AzureRmApiManagementTenantGitConfiguration -Context $context -Force -Branch "master"
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}
# =================================================================
# END - Push Crowns APIM code to the designated APIM instance
# =================================================================


