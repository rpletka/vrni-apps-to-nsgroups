Set-SecretStoreConfiguration -Authentication None -Confirm:$false
#If LocalVault doesn't exist create Local Vault
$Vault=Get-SecretVault LocalStore -ErrorAction SilentlyContinue
if ( $Vault.IsDefault ) {
    Write-Host "LocalStore Vault exists.  Skipping..."
}
else {
    Write-Host "Creating LocalStore Vault"
    Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore  -DefaultVault
}

#Add credentials to vault
$vrniCreds=Get-Secret -name vrni -ErrorAction SilentlyContinue
if ($vrniCreds -eq $null) {
    Get-Credential -username "admin@local" -Title "The next prompt is to add your vRNI admin@local Credentals to the Vault" | set-secret -name vrni
}
else {
    Write-Host "vrniCreds already exist.  Skipping..."
}

$nsxCreds=Get-Secret -name nsx -ErrorAction SilentlyContinue
if ($nsxCreds -eq $null) {
    Get-Credential -username admin -Title "The next prompt is to store your NSX admin Credentals to the Vault" | set-secret -name nsx
}
else {
    Write-Host "vrniCreds already exist.  Skipping..."
}