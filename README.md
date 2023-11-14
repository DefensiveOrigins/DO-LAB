![](images/APT1.jpg)


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

[![Deploy DO-LAB Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/%68%74%74%70%73%3a%2f%2f%72%61%77%2e%67%69%74%68%75%62%75%73%65%72%63%6f%6e%74%65%6e%74%2e%63%6f%6d%2f%44%65%66%65%6e%73%69%76%65%4f%72%69%67%69%6e%73%2f%44%4f%2d%4c%41%42%2f%6d%61%69%6e%2f%61%7a%75%72%65%2d%64%65%70%6c%6f%79%2e%6a%73%6f%6e/createUIDefinitionUri/%68%74%74%70%73%3a%2f%2f%72%61%77%2e%67%69%74%68%75%62%75%73%65%72%63%6f%6e%74%65%6e%74%2e%63%6f%6d%2f%44%65%66%65%6e%73%69%76%65%4f%72%69%67%69%6e%73%2f%44%4f%2d%4c%41%42%2f%6d%61%69%6e%2f%75%69%64%65%66%69%6e%69%74%69%6f%6e%2e%6a%73%6f%6e)

## Azure Cloud Locations/Regions
While the deployment within Azure should be region agnostic, some deployed resources may not be available in all regions.
The following locations have specifically been tested:
* US East (any)
* US West (any)
* US Central (any)

## Training Course Pre-Requisites
Are you attending a Defensive Origins training course that utilizes the Defensive Origins Azure Lab Environment?  See the below links for additional information on the DOAZLab Pre-Requisites for Defensive Origins training courses. 
* https://github.com/DefensiveOrigins/APT-PreReqs

## Lab Environment
* Windows Server 2022 /w Active Directory.
  * Domain: doazlab.com
* Windows Workstation 23h2-pro
* Ubuntu 22.04LTS C2 with Metasploit
* Sysmon Installation on Server and Workstation
* Microsoft Sentinel Log Aggregation

# Upcoming Classes
New classes will be coming in 2024!

For more information on upcoming classes, see our classes at https://www.defensiveorigins.com.


# Acknowledgments
* Open Threat Research Forge: https://github.com/DefensiveOrigins/DO-LAB
* Microsoft Sentinel2Go: https://github.com/OTRF/Microsoft-Sentinel2Go
* OTRF Blacksmith Components: https://github.com/OTRF/Blacksmith
* Roberto Rodriguez (@Cyb3rWard0g)
* Sysmon Modular: https://github.com/olafhartong/sysmon-modular/wiki 

# License
 * GPLv3
