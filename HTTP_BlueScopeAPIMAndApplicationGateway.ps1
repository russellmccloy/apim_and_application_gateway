#[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("C:\Users\Rusty\Desktop\sub-appgtw-mex-dev01-ase.pfx"))

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

$resourceGroupName = "SubShared-resgrp-mex-dev01-ase";

$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -name publicIP01 -location "Australia Southeast" -AllocationMethod Dynamic
$publicip


$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName
$appgatewaysubnetdata = $vnet.Subnets[0]
$apimsubnetdata =       $vnet.Subnets[1]

$appgatewaysubnetdata
$apimsubnetdata

# Get-AzureRmApiManagement -ResourceGroupName $resourceGroupName - no APIM vnet yet
# Create an API Management Virtual Network object using the subnet $apimsubnetdata created above
$apimVirtualNetwork = New-AzureRmApiManagementVirtualNetwork -Location "Australia Southeast" -SubnetResourceId $apimsubnetdata.Id

#Upload the certificate with private key for the domain. For this example it will be *.contoso.net.
$certUploadResult = Import-AzureRmApiManagementHostnameCertificate -ResourceGroupName $resourceGroupName `
    -Name "sub-apimgt-mex-dev01-ase" -HostnameType "Proxy" -PfxPath "C:\Users\Rusty\Desktop\api.bluescope.net.pfx" -PfxPassword "Wombat22" -PassThru


# Once the certificate is uploaded, create a hostname configuration object for the proxy with a hostname of api.contoso.net, as the example certificate provides authority for the *.contoso.net domain.
$proxyHostnameConfig = New-AzureRmApiManagementHostnameConfiguration -CertificateThumbprint $certUploadResult.Thumbprint -Hostname "blueScopeAPI"
    
$result = Set-AzureRmApiManagementHostnames -Name "sub-apimgt-mex-dev01-ase" -ResourceGroupName $resourceGroupName -ProxyHostnameConfiguration $proxyHostnameConfig

# Create a public IP resource publicIP01 in resource group apim-appGw-RG for the West US region.
# DONT THINK WE NEED THIS STEP
# $publicip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -name "publicIP01" -location "Australia Southeast" -AllocationMethod Dynamic
# An IP address is assigned to the application gateway when the service starts.



# => RUN FROM HERE ==========>

$apimService = Get-AzureRmApiManagement -ResourceGroupName $resourceGroupName

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName
$appgatewaysubnetdata = $vnet.Subnets[0]
$apimsubnetdata =       $vnet.Subnets[1]

#$publicip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name sub-ipaddrdatgtw-mex-dev01-ase
$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -name "publicIP01" -location "Australia Southeast" -AllocationMethod Dynamic


$gipconfig = New-AzureRmApplicationGatewayIPConfiguration -Name "gatewayIP01" -Subnet $appgatewaysubnetdata

# Configure the front-end IP port for the public IP endpoint. This port is the port that end users connect to.
$fp01 = New-AzureRmApplicationGatewayFrontendPort -Name "port01"  -Port 443

# Configure the front-end IP with public IP endpoint.
$fipconfig01 = New-AzureRmApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip

# Configure the certificate for the Application Gateway, used to decrypt and re-encrypt the traffic passing through.
$cert = New-AzureRmApplicationGatewaySslCertificate -Name "appGatewaySslCert" -CertificateFile "C:\Users\Rusty\Desktop\api.bluescope.net.pfx" -Password "Wombat22"

# Create the HTTP listener for the Application Gateway. Assign the front-end IP configuration, port, and ssl certificate to it.
$listener = New-AzureRmApplicationGatewayHttpListener -Name "appGatewayHttpsListener" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert

# Create a custom probe to the API Management service ContosoApi proxy domain endpoint. The path /status-0123456789abcdef is a default health endpoint hosted on all the API Management services. Set api.contoso.net as a custom probe hostname to secure it with SSL certificate.
# The hostname contosoapi.azure-api.net is the default proxy hostname configured when a service named contosoapi is created in public Azure.
#$apimprobe = New-AzureRmApplicationGatewayProbeConfig -Name "apimproxyprobe" -Protocol Http -HostName "blueScopeAPI" -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8

# Upload the certificate to be used on the SSL-enabled backend pool resources.
$authcert = New-AzureRmApplicationGatewayAuthenticationCertificate -Name "whitelistcert1" -CertificateFile "C:\Users\Rusty\Desktop\BlueScopeAuthCert.cer"

# Configure HTTP backend settings for the Application Gateway. This includes setting a time-out limit for backend request after which they are cancelled. This value is different from the probe time-out.
$apimPoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolSetting" -Port 443 -Protocol Https -CookieBasedAffinity "Disabled" -Probe $apimprobe -AuthenticationCertificates $authcert -RequestTimeout 180

# Configure a back-end IP address pool named apimbackend with the internal virtual IP address of the API Management service created above.
$apimProxyBackendPool = New-AzureRmApplicationGatewayBackendAddressPool -Name "apimbackend" -BackendIPAddresses $apimService.StaticIPs[0]

# Configure URL rule paths for the back-end pools. This enables selecting only some of the APIs from API Management for being exposed to the public. (e.g. if there are Echo API (/echo/), Calculator API (/calc/) etc. make only Echo API accessible from Internet).
# The following example creates a simple rule for the "/echo/" path routing traffic to the back-end "apimProxyBackendPool".
$echoapiRule = New-AzureRmApplicationGatewayPathRuleConfig -Name "externalapis" -Paths "/echo/*" -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolSetting
$urlPathMap = New-AzureRmApplicationGatewayUrlPathMapConfig -Name "urlpathmap" -PathRules $echoapiRule -DefaultBackendAddressPool $apimProxyBackendPool -DefaultBackendHttpSettings $apimPoolSetting
# The above step ensures that only requests for the path "/echo" are allowed through the Application Gateway. Requests to other APIs configured in API Management will throw 404 errors from Application Gateway when accessed from the Internet.

# Create a rule setting for the Application Gateway to use URL path-based routing.
$rule01 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "rule1" -RuleType PathBasedRouting -HttpListener $listener -UrlPathMap $urlPathMap

# Configure the number of instances and size for the Application Gateway. Here we are using the WAF SKU for increased security of the API Management resource.
$sku = New-AzureRmApplicationGatewaySku -Name "WAF_Medium" -Tier "WAF" -Capacity 2
# Configure WAF to be in "Prevention" mode.
$config = New-AzureRmApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Prevention"

# Create Application Gateway
# Create an Application Gateway with all the configuration objects from the preceding steps.
$appgw = New-AzureRmApplicationGateway -Name "appgwtest" -ResourceGroupName $resourceGroupName `
    -Location "Australia Southeast" -BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $apimPoolSetting `
    -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener `
    -UrlPathMaps $urlPathMap -RequestRoutingRules $rule01 -Sku $sku <#-WebApplicationFirewallConfig $config #> -SslCertificates $cert `
    -AuthenticationCertificates $authcert <#-Probes $apimprobe #>

# CNAME the API Management proxy hostname to the public DNS name of the Application Gateway resource
# Once the gateway is created, the next step is to configure the front end for communication. When using a public IP, Application Gateway requires a dynamically assigned DNS name, which may not be easy to use.
# The Application Gateway's DNS name should be used to create a CNAME record which points the APIM proxy host name (e.g. api.contoso.net in the examples above) to this DNS name. To configure the frontend IP CNAME record, retrieve the details of the Application Gateway and its associated IP/DNS name using the PublicIPAddress element. The use of A-records is not recommended since the VIP may change on restart of gateway.
Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name "publicIP01"


# Get-AzureRmApplicationGatewayProbeConfig -Name MyTempHealthProbe -ApplicationGateway $appgw
