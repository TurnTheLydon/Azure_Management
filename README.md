# Azure Management
This tool is currently only in the phases of development to provide simple Azure Tenant Management from Azure Cloud Shell or Windows Terminal. Follow for updates and changes

** I am currently in the process of rewriting this tool in Azure CLI rather than PS for compatibility reasons within Azure. **

This tool will be aimed to provide simple management of Azure services and users via Azure Cloud Shell or PowerShell session via Windows Terminal

I will update the below variable list as additional variables are added

This tool can also be obtained via wget from https://turnthelydon.com/gallery/AzManage.txt

Azure Cloud Shell & Windows Terminal: ```wget https://turnthelydon.com/gallery/AzManage.txt -O AzManage.ps1 ```

# Currently the following variables are in use:
    #Resource Group Settings
        #$rg
        #$location
    #Network Configuration
        #$vnet_name
        #$sub_name
        #$ip_range
        #$ip_subnet
        #$ip_nsg
    #Virutal Machine Configuration
        #$vmsize
        #$VMType
        #$vmname
        #$virtual_mac
        #$storage_acc
    #Configure Azure AD DNS Service
        #$enAADDS
        #$AADDSSub
    #Additional variables
        #$ExistVNet
        #$nsg
        #$AzSub
        #$ManDomain
        #$AADMGMT
