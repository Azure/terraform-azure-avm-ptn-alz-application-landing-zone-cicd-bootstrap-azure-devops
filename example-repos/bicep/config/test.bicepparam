using './main.bicep'

param workloadName = 'demo'
param environmentName = 'test'
param virtualNetworkAddressSpace = '10.1.0.0/16'
param subnetAddressPrefix = '10.1.0.0/24'
param virtualMachineSku = 'Standard_B1ls'
param tags = {
  deployed_by: 'bicep'
  environment: 'test'
}
