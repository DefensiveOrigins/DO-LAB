![](images/DOAZLab2025.png)

# Defensive Origins Lab Environment
The  Defensive Origins Lab (DO-LAB) Environment is used during the Defensive Origins training classes by Defensive Origins, AntiSyphon Training, and Black Hills Information Security.
<!-- Start Document Outline -->

* [Deploy Lab Environment](#deploy-lab-environment)
	* [Azure Cloud Locations/Regions](#azure-cloud-locationsregions)
	* [Training Course Pre-Requisites](#training-course-pre-requisites)
* [Lab Environment](#lab-environment)
* [Upcoming Classes](#upcoming-classes)
* [Acknowledgments](#acknowledgments)
* [License](#license)

<!-- End Document Outline -->



# Deploy Lab Environment

Click the button below to start the deployment of the Defensive Origins Lab Environment within your Azure account.

## [![Deploy DO-LAB Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/%68%74%74%70%73%3A%2F%2F%72%61%77%2E%67%69%74%68%75%62%75%73%65%72%63%6F%6E%74%65%6E%74%2E%63%6F%6D%2F%44%65%66%65%6E%73%69%76%65%4F%72%69%67%69%6E%73%2F%44%4F%2D%4C%41%42%2F%6D%61%69%6E%2F%44%65%70%6C%6F%79%2D%4C%41%42%2F%61%7A%75%72%65%2D%64%65%70%6C%6F%79%2E%6A%73%6F%6E/createUIDefinitionUri/%68%74%74%70%73%3A%2F%2F%72%61%77%2E%67%69%74%68%75%62%75%73%65%72%63%6F%6E%74%65%6E%74%2E%63%6F%6D%2F%44%65%66%65%6E%73%69%76%65%4F%72%69%67%69%6E%73%2F%44%4F%2D%4C%41%42%2F%6D%61%69%6E%2F%44%65%70%6C%6F%79%2D%4C%41%42%2F%75%69%64%65%66%69%6E%69%74%69%6F%6E%2E%6A%73%6F%6E)

[![Deploy DO-LAB Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/%68%74%74%70%73%3A%2F%2F%72%61%77%2E%67%69%74%68%75%62%75%73%65%72%63%6F%6E%74%65%6E%74%2E%63%6F%6D%2F%64%70%63%79%62%75%63%6B%2F%44%4F%2D%4C%41%42%2F%6D%61%69%6E%2F%44%65%70%6C%6F%79%2D%4C%41%42%2F%61%7A%75%72%65%2D%64%65%70%6C%6F%79%2E%6A%73%6F%6E/createUIDefinitionUri/%68%74%74%70%73%3A%2F%2F%72%61%77%2E%67%69%74%68%75%62%75%73%65%72%63%6F%6E%74%65%6E%74%2E%63%6F%6D%2F%64%70%63%79%62%75%63%6B%2F%44%4F%2D%4C%41%42%2F%6D%61%69%6E%2F%44%65%70%6C%6F%79%2D%4C%41%42%2F%75%69%64%65%66%69%6E%69%74%69%6F%6E%2E%6A%73%6F%6E)

## Azure Cloud Locations/Regions
While the deployment within Azure should be region agnostic, some deployed resources may not be available in all regions.
The following locations have specifically been tested:
* US East (any)
* US West (any)
* US Central (any)

## Training Course Pre-Requisites
Are you attending a Defensive Origins training course that utilizes the Defensive Origins Azure Lab Environment?  See the below links for additional information on the DOAZLab Pre-Requisites for Defensive Origins training courses. 

Assumed Compromise - Methodology With Detections and Microsoft Sentinel
* https://github.com/DefensiveOrigins/AC-PreReqs

Attack Detect Defend:
* https://github.com/DefensiveOrigins/ADD-PreReqs

Applied Purple Teaming:
* https://github.com/DefensiveOrigins/APT-PreReqs

## Lab Environment
* Windows Server 2022 /w Active Directory.
  * Domain: doazlab.com
* Windows Workstation 
* Ubuntu 22.04LTS 
* Sysmon Installation on Server and Workstation
* Microsoft Sentinel & Log Analytics

| ![Labenv](images/labenv.png) | 
|----------------------------------------------------------|


# Acknowledgments
* Open Threat Research Forge: https://github.com/DefensiveOrigins/DO-LAB
* Microsoft Sentinel2Go: https://github.com/OTRF/Microsoft-Sentinel2Go
* OTRF Blacksmith Components: https://github.com/OTRF/Blacksmith
* Roberto Rodriguez (@Cyb3rWard0g)
* Sysmon Modular: https://github.com/olafhartong/sysmon-modular/wiki 

# License
 * GPLv3
