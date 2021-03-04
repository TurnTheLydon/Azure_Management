# Azure Baseline Configuration Tool
# Jordan Lydon - 2021

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
