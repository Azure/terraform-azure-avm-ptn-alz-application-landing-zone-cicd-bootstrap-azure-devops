targetScope = 'resourceGroup'

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The workload name segment.')
param workloadName string

@description('The environment name segment.')
param environmentName string

@description('The virtual network address space.')
param virtualNetworkAddressSpace string = '10.0.0.0/16'

@description('The subnet address prefix.')
param subnetAddressPrefix string = '10.0.0.0/24'

@description('The virtual machine SKU.')
param virtualMachineSku string = 'Standard_B1ls'

@description('Tags to apply to all resources.')
param tags object = {}

var resourceNames = {
  virtualNetwork: 'vnet-${workloadName}-${environmentName}-${location}-001'
  subnet: 'snet-${workloadName}-${environmentName}-${location}-001'
  networkInterface: 'nic-${workloadName}-${environmentName}-${location}-001'
  virtualMachine: 'vm-${workloadName}-${environmentName}-001'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: resourceNames.virtualNetwork
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpace
      ]
    }
    subnets: [
      {
        name: resourceNames.subnet
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: resourceNames.networkInterface
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: resourceNames.virtualMachine
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSku
    }
    osProfile: {
      computerName: resourceNames.virtualMachine
      adminUsername: 'azureuser'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...'
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
  zones: [
    '1'
  ]
}
