<#
    .NOTES
    ===========================================================================
     Created by:    Ryan Pletka
     Organization:  VMware
     Email:         rpletka@vmware.com
    ===========================================================================
    .DESCRIPTION
        This scrpt will syncronize applications from vRealize Network Insight to NSX-T by:
            - Itterate through all the applcations in vRNI
            - Create or update a group for each application with membership criteria of scope vrniApplication and tag equal to the vRNI Applciation name.
            - Tag the VMs in NSX with a scope of vrniApplication and tag equal to the vRNI Applciation name
            - Note the script does not currently remove deleted application groups or tags from VMs that are removed from applications
    .EXAMPLE
        ./vrni-apps-to-nsgroups.ps1
#>

Import-Module PowervRNI
Import-Module PowerNSX



#Server Configuration
$vRNI_Server="vrni.far-away.galaxy"
$NSX_Server="nsx-t-mgr.far-away.galaxy"

#The logic can lookup the NSX vms by name or UUID.  Lookup by name is a little faster but there could be multiple vms with the same name.  Recommend leaving useUUID set to true.
$useUUID=$true

#Reconnect if there isn't an active vrni connection
$start_time=get-date
if ($nule -eq $defaultvRNIConnection.AuthTokenExpiry -or $defaultvRNIConnection.AuthTokenExpiry -lt $start_time) { 
    Write-Host "Connecting to $vRNI_Server"
    $vrniCreds=Get-Secret -name vrni
    Connect-vRNIServer -Server $vRNI_Server -Credential $vrniCreds | Format-List
}
else { Write-Host "Using existing connection to $vrni_Server"}

#Reconnect if there isn't an active NSX connection
if ($nule -eq $global:DefaultNsxtServers.User ) { 
    Write-Host "Connecting to $NSX_Server (Standby this is a very long operation)..."
    $nsxCreds=Get-Secret -name nsx
    Connect-NsxtServer -Server $NSX_Server -Credential $nsxCreds | Format-List
}
else { Write-Host "Using existing connection to $NSX_Server"}

$domain_id="default"
Write-Host "Getting NSX Policy Service"
$policy_service=Get-NsxtPolicyService com.vmware.nsx_policy.infra.domains.groups

if ($useUUID){
    Write-Host "Pre-loading vrni vms (Standby this is a long operation)..."
    $vrni_vms=get-vrnivm
}
Write-Host "Pre-loading NSX vms..."
$vm_service=get-nsxtservice com.vmware.nsx.fabric.virtual_machines
$nsx_vms=$vm_service.list().results

#Itterate through all the vrni apps
get-vrniapplication | ForEach-Object {
    $currentApplication = $_
    Write-Host "Processing App $($currentApplication.Name)... "
    $group_id=$currentApplication.Name

    #Create/update an NS group named for the currentApplicaiton     
    Write-Host "Creating/updating group $group_id"

    $group = $policy_service.Help.patch.group.Create()
    $group.display_name = $currentApplication.Name
    $group.description = "This group is managed by vrni-apps-to-nsgroups.ps1"
    
    # Create an empty list of expressions.
    $group.expression = $policy_service.Help.patch.group.expression.Create()
    # Create a single expression of type Condition. The resource_type field is prefilled with the correct value.
    $expression = $policy_service.Help.patch.group.expression.Element.condition.Create()
    $expression.member_type = "VirtualMachine"
    $expression.value = "vrniApplication|" + $currentApplication.Name
    $expression.key = "Tag"
    $expression.scope_operator = "EQUALS"
    $expression.operator = "EQUALS"
    [void]($group.expression.Add($expression))

    $policy_service.patch($domain_id, $group_id, $group)
    Write-Host "Group Updated"
    
    Write-Host "Getting member Vms for " $currentApplication.Name
    #Itterate through the members of the app, lookup the VM in NSX by UUID or name and update the tags to match group criteria
    Get-vRNIApplicationMemberVM $currentApplication | ForEach-Object {
        $Member=$_
        if ($Member.entity_type -eq "VirtualMachine") {
            if ($useUUID){
                $vrni_vm=$vrni_vms|where-object { $_.entity_id -match $Member.entity_id}
            }
            else {
                $vrni_vm=Get-vRNIEntityName -EntityID $Member.entity_id
            }
            Write-Host "Processing VM $($vrni_vm.name)" 
        }
        else {
            Write-Host "Skipping non-VM member of type $($Member.entity_type)" 
        }
        #Lookup the NSX VM in list of NSX vms by UUID or name
        if ($useUUID){
            $nsx_vm = $nsx_vms |Where-Object {$_.external_id -eq $vrni_vm.vm_UUID}
        }
        else {
            $nsx_vm = $nsx_vms |Where-Object {$_.display_name -eq $vrni_vm.name}
        }
        
        #Create Tags object
        $tags = @(
            [pscustomobject]@{scope='vrniApplication';tag=$currentApplication.Name}
            #[pscustomobject]@{scope='vrniTier'; tag='TBD'}
        )
        #Update Tags on vm
        $vm_tag_update = @{external_id=$nsx_vm.external_id;tags=$tags}
        Write-Host "Updating tags"
        $vm_service.updatetags($vm_tag_update)
    }
}

$now=get-date
$elapsed= $now-$start_time
Write-Host "Completed in $($elapsed.TotalMinutes) Minutes"