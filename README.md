# We're working on it
We are working on an updated lab and ARM template.  We will be posting updates soon.  We acknlowege that the current state of this ARM template and lab deployer is broken.  We are not updating it and  we will update links to the new build when it is completed.

In the mean time, we'd recommend checking out Sentinel2Go: https://github.com/OTRF/Microsoft-Sentinel2Go

If you want to try our current version fo DO-LAB, click below to start the deployment of the Defensive Origins Lab Environment within your Azure account.

[![Deploy DO-LAB Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/%68%74%74%70%73%3a%2f%2f%72%61%77%2e%67%69%74%68%75%62%75%73%65%72%63%6f%6e%74%65%6e%74%2e%63%6f%6d%2f%44%65%66%65%6e%73%69%76%65%4f%72%69%67%69%6e%73%2f%44%4f%2d%4c%41%42%2f%6d%61%69%6e%2f%61%7a%75%72%65%2d%64%65%70%6c%6f%79%2e%6a%73%6f%6e/createUIDefinitionUri/%68%74%74%70%73%3a%2f%2f%72%61%77%2e%67%69%74%68%75%62%75%73%65%72%63%6f%6e%74%65%6e%74%2e%63%6f%6d%2f%44%65%66%65%6e%73%69%76%65%4f%72%69%67%69%6e%73%2f%44%4f%2d%4c%41%42%2f%6d%61%69%6e%2f%75%69%64%65%66%69%6e%69%74%69%6f%6e%2e%6a%73%6f%6e) 

## Defensive Origins Lab Environment
Defensive Origins Lab  Environment is used within the Defensive Origins courses provided by Defensive Origins, AntiSyphon Security, and Black Hills Information Security.

For more information on upcoming classes, see our classes at https://www.defensiveorigins.com.

## Upcoming Classes: 
New classes will be coming in 2024!


# Deployment 

A new ARM template is on its way soon. 

## Training Course Pre-Requisites
Are you attending a Defensive Origins training course that utilizes the Defensive Origins Azure Lab Environment?  See the below links for additional information on the DOAZLab Pre-Requisites for Defensive Origins training courses. 
* https://github.com/DefensiveOrigins/APT-PreReqs

## Location
While the deployment within Azure should be region agnostic, some deployed resources may not be available in all regions.
The following locations have specifically been tested:
* US EAST (any)
* US WEST (any)

# Components
* Windows Server 2022 /w Active Directory.
  * Domain: doazlab.com
* Windows Workstation 23h2-pro
* Ubuntu 22.04LTS C2 with Metasploit
* Sysmon Installation on Server and Workstation
* Microsoft Sentinel Log Aggregation

# Acknowledgments
* Open Threat Research Forge: https://github.com/DefensiveOrigins/DO-LAB
* Microsoft Sentinel2Go: https://github.com/OTRF/Microsoft-Sentinel2Go
* OTRF Blacksmith Components: https://github.com/OTRF/Blacksmith
* Roberto Rodriguez (@Cyb3rWard0g)
* Sysmon Modular: https://github.com/olafhartong/sysmon-modular/wiki 

# License
 * GPLv3
