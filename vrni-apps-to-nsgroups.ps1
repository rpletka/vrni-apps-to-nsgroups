Import-Module PowervRNI
Import-Module PowerNSX

#The logic can lookup the NSX vms by name or UUID.  lookup by name is a little faster but there could be multiple vms with the same name. Recommend leaving useUUID set to True.
$useUUID=$true
$vRNI_Server="vrni.far-away.galaxy"
$NSX_Server="nsx-t-mgr.far-away.galaxy"

#Reconnect if there isn't an active vrni connection
$now=get-date
if ($defaultvRNIConnection.AuthTokenExpiry -eq $null || $defaultvRNIConnection.AuthTokenExpiry -le $now) { 
    Write-Host "Connecting to $vRNI_Server"
    $vrniCreds=Get-Secret -name vrni
    Connect-vRNIServer -Server $vRNI_Server -Credential $vrniCreds 
}
else { Write-Host "Using existing connection to $vrni_Server"}

#Reconnect if there isn't an active NSX connection
if ($global:DefaultNsxtServers.User -eq $null ) { 
    Write-Host "Connecting to $NSX_Server (Standby this is a long operation)..."
    $nsxCreds=Get-Secret -name nsx
    Connect-NsxtServer -Server $NSX_Server -Credential $nsxCreds
}
else { Write-Host "Using existing connection to $NSX_Server"}

$domain_id="default"
$group_id="PowerNSX-Test"
Write-Host "Getting NSX Policy Service"
$service=Get-NsxtPolicyService com.vmware.nsx_policy.infra.domains.groups
#$service.list("default")

if ($useUUID){
    Write-Host "Pre-loading vrni vms..."
    $vrni_vms=get-vrnivm
}
Write-Host "Pre-loading NSX vms..."
$vm_service=get-nsxtservice com.vmware.nsx.fabric.virtual_machines
$nsx_vms=$vm_service.list().results

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
            Write-Host "Getting vrni VM for entity_id $Entity (Standby this is a long operation)..."
            if ($useUUID){
                $vrni_vm=$vrni_vms|where-object { $_.entity_id -match $Entity}
            }
            else {
                $vrni_vm=Get-vRNIEntityName -EntityID $Entity
            }
            Write-Host "Processing VM " $vrni_vm.name "..."
        }
        else {
            Write-Host "Skipping " $Member.entity_type
        }
        if ($useUUID){
            $vm=$nsx_vms |where {$_.external_id -eq $vrni_vm.vm_UUID}
        }
        else {
            $vm=$nsx_vms |where {$_.display_name -eq $vrni_vm.name}
        }
        $tags = @(
            [pscustomobject]@{scope='vrniApplication';tag=$currentApplication.Name}
            #[pscustomobject]@{scope='vrniTier'; tag='TBD'}
        )
        $vm_tag_update = @{external_id=$vm.external_id;tags=$tags}
        Write-Host "Updating tags..."
        $vm_service.updatetags($vm_tag_update)
        Write-Host "Update complete"
    }
}

$start_time=$now
$now=get-date
$elapsed= $now-$start_time
Write-Host "Completed in " $elapsed.Seconds " Seconds"
