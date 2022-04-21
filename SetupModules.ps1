#Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted 
Install-Module PowervRNI 
Find-Module PowerNSX | Install-Module -scope CurrentUser -SkipPublisherCheck
#Remove-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore
#Uninstall-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false