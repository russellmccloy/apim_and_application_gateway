$resourceGroupName = "apim-Generic-RG"
$resourceGroupRegion = "Australia Southeast"

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

New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupRegion 

#################################################################################
# Create a Virtual Network and a subnet for the application gateway             #
#################################################################################
# Step 1
# Assign the address range 10.0.1.0/24 to the subnet variable to be used for API Management while creating a Virtual Network.
$apimsubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "subApim02" -AddressPrefix "10.0.1.0/24"

# Step 2
# Assign the address range 10.0.2.0/24 to the subnet variable to be used for Application Gateway while creating a Virtual Network.
$appgatewaysubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "subAppGW" -AddressPrefix "10.0.2.0/24"

# Step 3
#Create a Virtual Network named appgwvnet in resource group $resourceGroupName for the $resourceGroupRegion region using the prefix 10.0.0.0/16 with subnets 10.0.1.0/24 and 10.0.2.0/24.
$vnet = New-AzureRmVirtualNetwork -Name "appgwvnet" -ResourceGroupName $resourceGroupName -Location $resourceGroupRegion -AddressPrefix "10.0.0.0/16" -Subnet $appgatewaysubnet,$apimsubnet
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name "appgwvnet"
# Step 4
# Assign a subnet variable for the next # Steps
$appgatewaysubnetdata=$vnet.Subnets[0]
$apimsubnetdata=$vnet.Subnets[1]

Write-Host $appgatewaysubnetdata.Name
Write-Host $apimsubnetdata.Name

#################################################################################
# Create an API Management service inside a VNET configured in internal mode    #
#################################################################################
#The following example shows how to create an API Management service in a VNET configured for internal access only.
# Step 1
# Create an API Management Virtual Network object using the subnet $apimsubnetdata created above.
$apimVirtualNetwork = New-AzureRmApiManagementVirtualNetwork -Location $resourceGroupRegion -SubnetResourceId $apimsubnetdata.Id

# Step 2
# Create an API Management service inside the Virtual Network.
$apimService = New-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Location $resourceGroupRegion -Name "ContosoApi" -Organization "Contoso" -AdminEmail "admin@contoso.com" <# -VirtualNetwork $apimVirtualNetwork -VpnType "Internal" #> -Sku "Developer"
# After the above command succeeds refer to DNS Configuration required to access internal VNET API Management service to access it.
$apimService = Get-AzureRmApiManagement -Name ContosoApi



#################################################################################
# Set-up a custom domain name in API Management                                 #
#################################################################################
# Step 1
# Upload the certificate with private key for the domain. For this example it will be *.contoso.net.
$certUploadResult = Import-AzureRmApiManagementHostnameCertificate -ResourceGroupName $resourceGroupName -Name "ContosoApi" -HostnameType "Proxy" -PfxPath "C:\Users\Rusty\Desktop\blueScopeAPI.contosoapi.net.pfx" -PfxPassword "Wombat22" -PassThru

# Step 2
# Once the certificate is uploaded, create a hostname configuration object for the proxy with a hostname of blueScopeAPI.contosoapi.net, as the example certificate provides authority for the *.contosoapi.net domain.
$proxyHostnameConfig = New-AzureRmApiManagementHostnameConfiguration -CertificateThumbprint $certUploadResult.Thumbprint -Hostname "blueScopeAPI.contosoapi.net"
$result = Set-AzureRmApiManagementHostnames -Name "ContosoApi" -ResourceGroupName $resourceGroupName -ProxyHostnameConfiguration $proxyHostnameConfig




#################################################################################
# Create a public IP address for the front-end configuration                    #
#################################################################################
# Create a public IP resource publicIP01 in resource group $resourceGroupName for the $resourceGroupRegion region.
$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -name "publicIP01" -location $resourceGroupRegion -AllocationMethod Dynamic
# An IP address is assigned to the application gateway when the service starts.




#################################################################################
# Create application gateway configuration                                      #
#################################################################################
# All configuration items must be set up before creating the application gateway. The following steps create the configuration items that are needed for an application gateway resource.

# Step 1
# Create an application gateway IP configuration named gatewayIP01. When Application Gateway starts, it picks up an IP address from the subnet configured and route network traffic to the IP addresses in the back-end IP pool. Keep in mind that each instance takes one IP address.
$gipconfig = New-AzureRmApplicationGatewayIPConfiguration -Name "gatewayIP01" -Subnet $apimsubnetdata # SWAPPED $appgatewaysubnetdata

# Step 2
# Configure the front-end IP port for the public IP endpoint. This port is the port that end users connect to.
$fp01 = New-AzureRmApplicationGatewayFrontendPort -Name "port01"  -Port 443
#$fp01 = New-AzureRmApplicationGatewayFrontendPort -Name "port01"  -Port 80


# Step 3
# Configure the front-end IP with public IP endpoint.
$fipconfig01 = New-AzureRmApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip

# Step 4
# Configure the certificate for the Application Gateway, used to decrypt and re-encrypt the traffic passing through.
$cert = New-AzureRmApplicationGatewaySslCertificate -Name "cert01" -CertificateFile "C:\Users\Rusty\Desktop\blueScopeAPI.contosoapi.net.pfx" -Password "Wombat22"

# Step 5
# Create the HTTP listener for the Application Gateway. Assign the front-end IP configuration, port, and ssl certificate to it.
$listener = New-AzureRmApplicationGatewayHttpListener -Name "listener01" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert
# HTTP $listener = New-AzureRmApplicationGatewayHttpListener -Name "listener01" -Protocol "Http" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 # -SslCertificate $cert

# Step 6
# Create a custom probe to the API Management service ContosoApi proxy domain endpoint. The path /status-0123456789abcdef is a default health endpoint hosted on all the API Management services. Set api.contoso.net as a custom probe hostname to secure it with SSL certificate.
# Note
# The hostname contosoapi.azure-api.net is the default proxy hostname configured when a service named contosoapi is created in public Azure.
$apimprobe = New-AzureRmApplicationGatewayProbeConfig -Name "apimproxyprobe" -Protocol "Http" -HostName "blueScopeAPI.contosoapi.net" -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
# HTTP $apimprobe = New-AzureRmApplicationGatewayProbeConfig -Name "apimproxyprobe" -Protocol "Http" -HostName "api.contoso.net" -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8

$AppGw = Get-AzureRmApplicationGateway -Name "appgwtest" -ResourceGroupName $resourceGroupName
$manuallySetupProbe = Get-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $AppGw -Name "MyManualHTTPSProbe"

# Step 7
# Upload the certificate to be used on the SSL-enabled backend pool resources.
$authcert = New-AzureRmApplicationGatewayAuthenticationCertificate -Name "whitelistcert1" -CertificateFile "C:\Users\Rusty\Desktop\BlueScopeAuthCert.cer"

# Step 8
# Configure HTTP backend settings for the Application Gateway. This includes setting a time-out limit for backend request after which they are cancelled. This value is different from the probe time-out.
$apimPoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolSettingHttps" -Port 443 -Protocol "Http" -CookieBasedAffinity "Disabled" -Probe $manuallySetupProbe -AuthenticationCertificates $authcert -RequestTimeout 180
# HTTP $apimPoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolSetting" -Port 80 -Protocol "Http" -CookieBasedAffinity "Disabled" -Probe $apimprobe <# -AuthenticationCertificates $authcert #> -RequestTimeout 180

$AppGw = Get-AzureRmApplicationGateway -Name "appgwtest" -ResourceGroupName $resourceGroupName
$manuallySetupapimPoolSetting  = Get-AzureRmApplicationGatewayBackendHttpSettings -ApplicationGateway $AppGw -Name "apimPoolSetting"

# Step 9
# Configure a back-end IP address pool named apimbackend with the internal virtual IP address of the API Management service created above.
$apimProxyBackendPool = New-AzureRmApplicationGatewayBackendAddressPool -Name "apimbackend" -BackendIPAddresses $apimService.StaticIPs[0]

# Step 10
# Configure URL rule paths for the back-end pools. This enables selecting only some of the APIs from API Management for being exposed to the public. (e.g. if there are Echo API (/echo/), Calculator API (/calc/) etc. make only Echo API accessible from Internet).
# The following example creates a simple rule for the "/echo/" path routing traffic to the back-end "apimProxyBackendPool".
$echoapiRule = New-AzureRmApplicationGatewayPathRuleConfig -Name "externalapis" -Paths "/echo/*" -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $manuallySetupapimPoolSetting
$urlPathMap = New-AzureRmApplicationGatewayUrlPathMapConfig -Name "urlpathmap" -PathRules $echoapiRule -DefaultBackendAddressPool $apimProxyBackendPool -DefaultBackendHttpSettings $manuallySetupapimPoolSetting
# The above step ensures that only requests for the path "/echo" are allowed through the Application Gateway. Requests to other APIs configured in API Management will throw 404 errors from Application Gateway when accessed from the Internet.

# Step 11
# Create a rule setting for the Application Gateway to use URL path-based routing.
$rule01 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "rule1" -RuleType PathBasedRouting -HttpListener $listener -UrlPathMap $urlPathMap

# Step 12
# Configure the number of instances and size for the Application Gateway. Here we are using the WAF SKU for increased security of the API Management resource.
$sku = New-AzureRmApplicationGatewaySku -Name "WAF_Medium" -Tier "WAF" -Capacity 2

# Step 13
# Configure WAF to be in "Prevention" mode.
$config = New-AzureRmApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Prevention"

#################################################################################
# Create Application Gateway                                                    #
#################################################################################
# Create an Application Gateway with all the configuration objects from the preceding steps.
$appgw = New-AzureRmApplicationGateway -Name "appgwtest" -ResourceGroupName $resourceGroupName -Location $resourceGroupRegion `
    -BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $manuallySetupapimPoolSetting -FrontendIpConfigurations $fipconfig01 `
    -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener -UrlPathMaps $urlPathMap -RequestRoutingRules $rule01 -Sku $sku `
    -WebApplicationFirewallConfig $config -SslCertificates $cert -AuthenticationCertificates $authcert -Probes $manuallySetupProbe 

# $appgw = New-AzureRmApplicationGateway -Name "appgwtest" -ResourceGroupName $resourceGroupName -Location $resourceGroupRegion `
#        -BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $apimPoolSetting <# -FrontendIpConfigurations $fipconfig01 #> `
#        -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener -UrlPathMaps $urlPathMap -RequestRoutingRules $rule01 -Sku $sku `
#        -WebApplicationFirewallConfig $config <# -SslCertificates $cert -AuthenticationCertificates $authcert #> -Probes $apimprobe




###################################################################################################################################
# CNAME the API Management proxy hostname to the public DNS name of the Application Gateway resource                              #
###################################################################################################################################
# Once the gateway is created, the next step is to configure the front end for communication. When using a public IP, Application Gateway requires a dynamically assigned DNS name, which may not be easy to use.
#The Application Gateway's DNS name should be used to create a CNAME record which points the APIM proxy host name (e.g. api.contoso.net in the examples above) to this DNS name. 
# To configure the frontend IP CNAME record, retrieve the details of the Application Gateway and its associated IP/DNS name using the PublicIPAddress element. 
# The use of A-records is not recommended since the VIP may change on restart of gateway.
# HTTPS: Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name "publicIP01"