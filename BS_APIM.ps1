New-SelfSignedCertificate -Subject "xxx" 

$CertPassword = ConvertTo-SecureString -String “xxxx” -Force –AsPlainText

Export-PfxCertificate -Cert cert:\LocalMachine\My\849DB7C058FE42A88CD624B8AC073D664C8F0775  -FilePath "C:\Users\Rusty\Desktop\api.xxxxx.net.pfx" -Password $CertPassword