This scrpt will read applications from vRealize Network Insight and create a group for each application with membership criteria and tag the vms to create dynamic membership of each application group.  The script will update existing groups and VMS.  It will add tags to vms but does not remove tags.

This was developed on powershell 7.2.2.

1. Run the SetupModules.ps1 one time to install PowerVRNI and PowerNSX
2. Run the SetupCredentialVault one time to store your credentials for vrni and PowerNSX
3. Update the nsx and vrni servers in vrni-apps-to-nsgroups.ps1 and run. Progress will be reported to the console groups will be added to NSX and vms will be tagged. 
