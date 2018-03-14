param
(
        [Parameter(Mandatory = $false)]
	    [String]$APIMManangementUrl = "management.apiau.bluescope.com",

        [Parameter(Mandatory = $false)]
	    [String]$BackendName = "orders_rdfs_startspmesrdfbatchprocing_funcapp_bslau_dev_aes_integt_au_bluescope_com",

        [Parameter(Mandatory = $false)]
	    [String]$BackendHostName = "orders-rdfs-startspmesrdfbatchprocing-funcapp-bslau-dev-aes.integt.au.bluescope.com"        
)

. "D:\MyDropbox\Dropbox (Personal)\My Documents\Technical - Azure Code Etc\General Powershell\Azure\login_to_azure.ps1"


Write-Host "Beginnning add backend entities to API Managemnt: ";

$url = "$APIMManangementUrl/backends/$BackendName`?api-version=2014-02-14-preview"

Write-Host "Url: $url";

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]";
$headers.Add("authorization", "SharedAccessSignature 594744902679ae0088030003&201706250258&eH1qLHxHY2DvsBoD0M+BeIQvL9gg1m7cjfYgvp5PsGQPSrKW5pQbcY2BQm8TEENyd8g8sAkUwdRW9lQyMcbEKg==");
$headers.Add("Content-Type", "application/json");

$bodyPart1 = ‘"host":"{0}"‘ -f $BackendHostName;
Write-Host "Host: $bodyPart1";

$skipCertificateChainValidation = ‘"skipCertificateChainValidation":"{0}"‘ -f $true;
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
