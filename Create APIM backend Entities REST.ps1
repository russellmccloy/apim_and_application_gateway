param
(
        [Parameter(Mandatory = $false)]
	    [String]$APIMManangementUrl = "management.apiau.xxxx.com",

        [Parameter(Mandatory = $false)]
	    [String]$BackendName = "orders_rdfs_startspmesrdfbatchprocing_funcapp_xxxx_dev_aes_integt_au_xxxx_com",

        [Parameter(Mandatory = $false)]
	    [String]$BackendHostName = "orders-rdfs-startspmesrdfbatchprocing-funcapp-xxxx-dev-aes.integt.au.xxxx.com"        
)

. "D:\MyDropbox\Dropbox (Personal)\My Documents\Technical - Azure Code Etc\General Powershell\Azure\login_to_azure.ps1"


Write-Host "Beginnning add backend entities to API Managemnt: ";

$url = "$APIMManangementUrl/backends/$BackendName`?api-version=2014-02-14-preview"

Write-Host "Url: $url";

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]";
$headers.Add("authorization", "SharedAccessSignature xxxx==");
$headers.Add("Content-Type", "application/json");

$bodyPart1 = �"host":"{0}"� -f $BackendHostName;
Write-Host "Host: $bodyPart1";

$skipCertificateChainValidation = �"skipCertificateChainValidation":"{0}"� -f $true;
$body = '{' + $bodyPart1 + ',' + $skipCertificateChainValidation + '}';

Write-Host "Body: $body";


try 
{
	$result = Invoke-WebRequest -Uri $url -Headers $headers -Method Put -Body $body -UseBasicParsing
	#Write-Host "Here is the generated DocDb collection: " $collection;
}
catch 
{
    Throw $_.Exception;
}
