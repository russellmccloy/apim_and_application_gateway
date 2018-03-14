New-SelfSignedCertificate -Subject "blueScopeAPI" 

$CertPassword = ConvertTo-SecureString -String “Wombat22” -Force –AsPlainText

Export-PfxCertificate -Cert cert:\LocalMachine\My\849DB7C058FE42A88CD624B8AC073D664C8F0775  -FilePath "C:\Users\Rusty\Desktop\api.bluescope.net.pfx" -Password $CertPassword