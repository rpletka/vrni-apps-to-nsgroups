# Sync vRNI Applications to NSX Security Groups

This scrpt will read applications from vRealize Network Insight to:
- Create or update a group for each application with membership criteria of scope vrniApplication and tag equal to the vRNI Applciation name.
- Tag the VMs in NSX with a scope of vrniApplication and tag equal to the vRNI Applciation name
- Note the script does not currently remove deleted application groups or tags from VMs that are removed from applications

## Installation Steps

1. Run the SetupModules.ps1 one time to install PowerVRNI and PowerNSX
2. Run the SetupCredentialVault one time on your target powershell host to store your credentials for vrni and PowerNSX
3. Update the nsx and vrni server variables at the top of vrni-apps-to-nsgroups.ps1. 

This was developed with the following versions:
- Powershell 7.2.2
- PowerNSX 3.0.119
- PowervRNI 6.51.185
- Microsoft.Powershell.SecretStore 1.0.6
- Microsoft.Powershell.SecretManagement 1.1.2

## Usage
Run vrni-apps-to-nsgroups.ps1 and/or schedule regular syncronization with the task scheduler of choice. Progress will be reported to the console.  Groups will be added/updated to NSX and NSX VM tags will be updated.

```
./vrni-apps-to-nsgroups.ps1
```

## Example

### Example 2 vRNI Saved Applications

![image](https://user-images.githubusercontent.com/11322247/164509226-0b31b955-1ccf-44cb-b365-a8e818a57eda.png)

### Example Initial Sync
Here is an example syncing 2 apps with 11 vms total.  Note the first run takes significantly longer than additional executions within the session time out.  This is because PowerNSX takes a few minutes to connect but the script reuses the connection if the token hasn't expired.

![image](https://user-images.githubusercontent.com/11322247/164519225-8eb84770-cada-4eee-9f21-f29397c9e1c1.png)

### Find vrni-apps-to-nsgroup Managed Groups in NSX

Easily find the groups that were created / updated by searching for vrn-apps-to-nsgroups to find all the groups with a description of "This group is managed by vrni-apps-to-nsgroups.ps1"

![image](https://user-images.githubusercontent.com/11322247/164509328-d54312e8-c4d8-4909-9b57-a9f8e71f3780.png)

### Example Group Definition

![image](https://user-images.githubusercontent.com/11322247/164510034-80f6acb3-403a-4ea8-83bf-bb8c6a560e95.png)

### Example Group Membership

![image](https://user-images.githubusercontent.com/11322247/164509588-a02034ed-b409-4973-ad17-14dc138b9b70.png)

### Additional Syncs Are Faster
Subsequent runs are faster because they reuse the existing connections to vRNI and NSX

![image](https://user-images.githubusercontent.com/11322247/164519443-f607dbf5-4075-4ad2-9a0a-1320d177e0b2.png)

## License

Network Insight Python SDK is licensed under GPL v2

Copyright © 2019 VMware, Inc. All Rights Reserved.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 2, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License version 2 for more details.

You should have received a copy of the General Public License version 2 along with this program. If not, see https://www.gnu.org/licenses/gpl-2.0.html.

The full text of the General Public License 2.0 is provided in the COPYING file. Some files may be comprised of various open source software components, each of which has its own license that is located in the source code of the respective component.”
