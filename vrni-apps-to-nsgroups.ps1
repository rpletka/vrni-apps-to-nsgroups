Import-Module PowervRNI
Import-Module PowerNSX

$vRNI_Server="vrni.far-away.galaxy"
$NSX_Server="nsx-t-mgr.far-away.galaxy"

#Reconnect if there isn't an active vrni connection
$now=get-date
if ($defaultvRNIConnection.AuthTokenExpiry -eq $null && $defaultvRNIConnection.AuthTokenExpiry -le $now) { 
    $vrniCreds=Get-Secret -name vrni
    Connect-vRNIServer -Server $vRNI_Server -Credential $vrniCreds 
}

#Reconnect if there isn't an active NSX connection
if ($global:DefaultNsxtServers.User -eq $null ) { 
    $nsxCreds=Get-Secret -name nsx
    Connect-NsxtServer -Server $NSX_Server -Credential $nsxCreds
} 

$domain_id="default"
$group_id="PowerNSX-Test"
$service=Get-NsxtPolicyService com.vmware.nsx_policy.infra.domains.groups
#$service.list("default")

# Creates the "group" input parameter.
$group = $service.Help.patch.group.Create()
$group.display_name = "PowerNSX-Test"
$group.description = "Created with Powershell"

$service.patch($domain_id, $group_id, $group)

# Creates an empty list of expressions.
$group.expression = $service.Help.patch.group.expression.Create()
# Creates a single expression of type Condition. The resource_type field is prefilled with the correct value.
$expression = $service.Help.patch.group.expression.Element.condition.Create()
$expression.member_type = "VirtualMachine"
$expression.value = "Application|TestApplication"
$expression.key = "Tag"
$expression.scope_operator = "EQUALS"
$expression.operator = "EQUALS"

[void]($group.expression.Add($expression))

$service.patch($domain_id, $group_id, $group)

get-vrniapplication | ForEach-Object {
    $currentApplication = $_
    Write-Host "Processing App " $currentApplication.Name "... "

    $domain_id="default"
    $group_id=$currentApplication.Name

    Write-Host "Updating group $group_id"
    $service=Get-NsxtPolicyService com.vmware.nsx_policy.infra.domains.groups
    $group = $service.Help.patch.group.Create()
    $group.display_name = $currentApplication.Name
    $group.description = "Created with Powershell"
    
    # Creates an empty list of expressions.
    $group.expression = $service.Help.patch.group.expression.Create()
    # Creates a single expression of type Condition. The resource_type field is prefilled with the correct value.
    $expression = $service.Help.patch.group.expression.Element.condition.Create()
    $expression.member_type = "VirtualMachine"
    $expression.value = "vrniApplication|" + $currentApplication.Name
    $expression.key = "Tag"
    $expression.scope_operator = "EQUALS"
    $expression.operator = "EQUALS"
    
    [void]($group.expression.Add($expression))

    $service.patch($domain_id, $group_id, $group)
    Write-Host "Group Updated"
    Write-Host "Getting member Vms for " $currentApplication.Name
    Get-vRNIApplicationMemberVM $currentApplication | ForEach-Object {
        $Member=$_
        $Entity=$_.entity_id 
        if ($Member.entity_type -eq "VirtualMachine") {
            Write-Host "Getting vrni VM for entity_id $Entity "
            $vrni_vm=get-vrnivm|where-object { $_.entity_id -match $Entity}
            Write-Host "Processing VM " $vrni_vm.name "..."
        }
        else {
            Write-Host "Skipping " $Member.entity_type
        }
        #$vrni_vm |format-list
        Write-Host "Getting NSX VM"
        $vm_service=get-nsxtservice com.vmware.nsx.fabric.virtual_machines
        $vm=$vm_service.list().results |where {$_.external_id -eq $vrni_vm.vm_UUID}
        #$vm|format-list
        $tags = @(ß
            [pscustomobject]@{scope='vrniApplication';tag=$currentApplication.Name}
            #[pscustomobject]@{scope='vrniTier'; tag='TBD'}
        )
        $vm_tag_update = @{external_id=$vm.external_id;tags=$tags}
        Write-Host "Updating tags..."
        $vm_service.updatetags($vm_tag_update)
        Write-Host "Update complete"
    }
}


#Get-Nsxtservice |Where-Object {$_.Name -match "com.vmware.nsx.fabric" } 
#