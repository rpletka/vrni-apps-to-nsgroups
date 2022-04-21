# Sync vRNI Applications to NSX Security Groups

This scrpt will read applications from vRealize Network Insight to:
- Itterate through all the applcations in vRNI
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

'''
./vrni-apps-to-nsgroups.ps1
'''

## Example

vRNI Saved Applications
![image](https://user-images.githubusercontent.com/11322247/164509226-0b31b955-1ccf-44cb-b365-a8e818a57eda.png)

Here is an example syncing 2 apps with 11 vms total.  Note the first run takes significantly longer than additional executions within the session time out.  This is because PowerNSX takes a few minutes to connect but the script reuses the connection if the token hasn't expired.

'''shell
PS /Users/rpletka/Documents/git/vrni-apps-to-nsgroups> ./vrni-apps-to-nsgroups.ps1
Connecting to vrni.far-away.galaxy

Server          : vrni.far-away.galaxy
AuthToken       : 9ELm6IZKqkgrqw+giS3FVg==
AuthTokenExpiry : 4/21/2022 5:11:26 PM

Connecting to nsx-t-mgr.far-away.galaxy (Standby this is a long operation)...

SessionSecret    : 
Uid              : /CisServer=admin@nsx-t-mgr.far-away.galaxy:443/
Id               : /CisServer=admin@nsx-t-mgr.far-away.galaxy:443/
ServiceUri       : https://nsx-t-mgr.far-away.galaxy/
User             : admin
IsConnected      : True
CisResource      : 
CisResourceState : 
RefCount         : 1
Port             : 443
Name             : nsx-t-mgr.far-away.galaxy

Getting NSX Policy Service
Pre-loading vrni vms (Standby this is a long operation)...
Pre-loading NSX vms...
Processing App  Books01 ... 
Creating/updating group Books01
Group Updated
Getting member Vms for  Books01
Processing VM  Books01-Web01
Updating tags
Processing VM  Books01-Web02
Updating tags
Processing VM  Books01-App01
Updating tags
Processing VM  Avi-se-chone
Updating tags
Processing VM  Books01-DB01
Updating tags
Processing VM  Avi-se-ghwqq
Updating tags
Processing VM  Books01-App02
Updating tags
Processing App  Horizon ... 
Creating/updating group Horizon
Group Updated
Getting member Vms for  Horizon
Processing VM  VDI-2
Updating tags
Processing VM  cs1
Updating tags
Processing VM  VDI-1
Updating tags
Completed in 2.44095005 Minutes
'''

![image](https://user-images.githubusercontent.com/11322247/164510034-80f6acb3-403a-4ea8-83bf-bb8c6a560e95.png)
![image](https://user-images.githubusercontent.com/11322247/164509328-d54312e8-c4d8-4909-9b57-a9f8e71f3780.png)
![image](https://user-images.githubusercontent.com/11322247/164509588-a02034ed-b409-4973-ad17-14dc138b9b70.png)

'''shell
PS /Users/rpletka/Documents/git/vrni-apps-to-nsgroups> ./vrni-apps-to-nsgroups.ps1
Using existing connection to vrni.far-away.galaxy
Using existing connection to nsx-t-mgr.far-away.galaxy
Getting NSX Policy Service
Pre-loading vrni vms (Standby this is a long operation)...
Pre-loading NSX vms...
Processing App Books01... 
Creating/updating group Books01
Group Updated
Getting member Vms for  Books01
Processing VM Books01-Web01
Updating tags
Processing VM Books01-Web02
Updating tags
Processing VM Books01-App01
Updating tags
Processing VM Avi-se-chone
Updating tags
Processing VM Books01-DB01
Updating tags
Processing VM Avi-se-ghwqq
Updating tags
Processing VM Books01-App02
Updating tags
Processing App Horizon... 
Creating/updating group Horizon
Group Updated
Getting member Vms for  Horizon
Processing VM VDI-2
Updating tags
Processing VM cs1
Updating tags
Processing VM VDI-1
Updating tags
Completed in 0.393595033333333 Minutes
'''
## License

Network Insight Python SDK is licensed under GPL v2

Copyright © 2019 VMware, Inc. All Rights Reserved.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 2, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License version 2 for more details.

You should have received a copy of the General Public License version 2 along with this program. If not, see https://www.gnu.org/licenses/gpl-2.0.html.

The full text of the General Public License 2.0 is provided in the COPYING file. Some files may be comprised of various open source software components, each of which has its own license that is located in the source code of the respective component.”