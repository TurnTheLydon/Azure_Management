# Azure Baseline Configuration Tool
# TurnTheLydon - 2021

# Actual variables and shit
    #Resource Group Settings
        $rg
        $location
    #Network Configuration
        $vnet_name
        $sub_name
        $ip_range
        $ip_subnet
        $ip_nsg
    #Virutal Machine Configuration
        $vmsize
        $VMType
        $vmname
        $virtual_mac
        $storage_acc
            #Get Variable Information
            Do {
            $rg = Read-Host "Please enter name for Resource Group"
            $location = Read-Host "Enter Geographic Location for Group"
            $vnet_name = Read-Host "Enter name for virtual network"
            $sub_name = Read-Host "Enter subnet name"
            $ip_range = Read-Host "Enter IP Range for Customer (10.0.0.0/16)"
            $ip_subnet = Read-Host "Enter primary subnet(10.0.1.0/24-/29)"
            $ip_nsg = Read-Host "Enter name for Azure NSG"
            $vmsize = Read-Host "Please specify VM size (Leave blank if unsure)"
                        if ($vmsize -eq ''){
                        do {    
                        Write-Host "Getting list of AzureVM Sizes, Please make a selection and copy name"                    
                        az vm list-skus --location $location --size Standard_D --output table
                        $vmsize = Read-Host "Please specify VM size"
                         } while ($vmsize -eq '')}
            $vmname = Read-Host "Enter name for Azure VM"
            $VMType = Read-Host "Is this a Desktop or Server? [D/S]"
            $storage_acc = "$vmname"+"_store"
                #Confirm Entries
                Write-Host "Please confirm the below inputs"
                Write-Host $rg
                Write-Host $location
                Write-Host $vnet_name
                Write-Host $sub_name
                Write-Host $ip_range
                Write-Host $ip_subnet
                Write-Host $ip_nsg
                Write-Host $vmsize
                Write-Host $vmname
                Write-Host $storage_acc
                $confirm = Read-Host "Please confirm all entries are correct [Y/N]"
                }
                Until ($confirm -eq 'Y')
                        if ($confirm -eq 'Y')
                        {
                            New-AzResourceGroup -Name $rg -Location $location
                            $LANSub = New-AzVirtualNetworkSubnetConfig -Name $sub_name -AddressPrefix $ip_subnet 
                            New-AzVirtualNetwork -ResourceGroupName $rg -Location $location -Name $vnet_name -AddressPrefix $ip_range -Subnet $LANSub
                            $virtual_mac = New-AzVM -Name $vmname -ResourceGroupName $rg -Location $location -VirtualNetworkName $vnet_name -SubnetName $sub_name -size $vmsize
                            $virtual_mac = Set-AzVMOperatingSystem -VM $virtual_mac -Windows -ComputerName $vmname -ProvisionVMAgent -EnableAutoUpdate
                            $virtual_mac = Add-AzVMNetworkInterface -VM $virtual_mac -Id $Nic.Id
                            if ($vmtype -eq 'D') {
                            $virtual_mac = Set-AzVMSourceImage -VM $virtual_mac -PublisherName 'MicrosoftWindowsServer' -Offer 'windows-10-20h2-vhd-server-prod-stage' -Skus 'datacenter-core-20h2-with-containers-smalldisk' -Version latest
                            }
                            if  ($VMType -eq 'S'){
                            $virtual_mac = Set-AzVMSourceImage -VM $virtual_mac -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest
                            }
                            New-AzVM -ResourceGroupName $rg -Location $location -VM $virtual_mac -AsJob -Verbose
                        }
                        Write-Host "Configuration Completed. Please check https://portal.azure.com in a few moments to see all resources populate."
# Configure Azure AD DNS Services
    #Variabools
        $enAADDS
        $AADDSSub
        $enAADDS = Read-Host "Do you need to configure Azure AD DNS Services? [Y/N]"
                    if($enAADDS -eq 'Y'){
                        Connect-AzAccount -UseDeviceAuthentication
                        Connect-AzureAD
                        New-AzureADServicePrincipal -AppId "2565bd9d-da50-47d4-8b85-4c97f669dc36"
                        $GroupObjectId = Get-AzureADGroup `
                        -Filter "DisplayName eq 'AAD DC Administrators'" | `
                        Select-Object ObjectId
                        if (!$GroupObjectId) {
                            $GroupObjectId = New-AzureADGroup -DisplayName "AAD DC Administrators" `
                              -Description "Delegated group to administer Azure AD Domain Services" `
                              -SecurityEnabled $true `
                              -MailEnabled $false `
                              -MailNickName "AADDCAdministrators"
                            }
                          else {
                            Write-Output "Admin group already exists."
                          }
                        Register-AzResourceProvider -ProviderNamespace Microsoft.AAD
                        $AADDSSub = Read-Host "Please enter subnet for AAD DS (Must be different from LAN subnet. Prefer /28 or /29 for this vNet)"
                        $ExistVNet = Get-AzVirtualNetwork -Name $vnet_name -ResourceGroupName $rg
                        Add-AzVirtualNetworkSubnetConfig -Name AADDS -VirtualNetwork $ExistVNet -AddressPrefix $AADDSSub
                        $ExistVNet | Set-AzVirtualNetwork

                        $NSGName = "aaddsNSG"

                        # Create a rule to allow inbound TCP port 3389 traffic from Microsoft secure access workstations for troubleshooting
                        $nsg201 = New-AzNetworkSecurityRuleConfig -Name AllowRD `
                            -Access Allow `
                            -Protocol Tcp `
                            -Direction Inbound `
                            -Priority 201 `
                            -SourceAddressPrefix CorpNetSaw `
                            -SourcePortRange * `
                            -DestinationAddressPrefix * `
                            -DestinationPortRange 3389

                        # Create a rule to allow TCP port 5986 traffic for PowerShell remote management
                        $nsg301 = New-AzNetworkSecurityRuleConfig -Name AllowPSRemoting `
                            -Access Allow `
                            -Protocol Tcp `
                            -Direction Inbound `
                            -Priority 301 `
                            -SourceAddressPrefix AzureActiveDirectoryDomainServices `
                            -SourcePortRange * `
                            -DestinationAddressPrefix * `
                            -DestinationPortRange 5986

                        # Create the network security group and rules
                        $nsg = New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $rg -Location $location -SecurityRules $nsg201,$nsg301

                        # Associate the network security group with the virtual network subnet
                        Set-AzVirtualNetworkSubnetConfig -Name AADDS `
                            -VirtualNetwork $ExistVNet `
                            -AddressPrefix $AADDSSub `
                            -NetworkSecurityGroup $nsg
                        $ExistVNet | Set-AzVirtualNetwork
                        $AzSub = Get-AzSubscription | ForEach-Object {$_.Id}
                        $ManDomain = Read-Host = "Input Domain for DNS Services"

                        New-AzResource -ResourceId "/subscriptions/$AzSub/resourceGroups/$rg/providers/Microsoft.AAD/DomainServices/$ManDomain" `
                        -ApiVersion 2021-01-01 `
                        -Location $location `
                        -Properties @{"DomainName"=$ManDomain; `
                            "SubnetId"="/subscriptions/$AzSub/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$Exist_VNet/subnets/DomainServices"} `
                        -Force -Verbose
                    }
                    if ($enAADDS -eq 'N'){

                    }
