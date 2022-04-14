Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module PowervRNI
Find-Module PowerNSX | Install-Module -scope CurrentUser
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore