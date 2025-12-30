/*
  Generic virtual network and subnet
  
  Description: 
  - Virtual network
  - Subnet
*/

@description('Name of the virtual network')
param vnetName string = 'private-vnet'

@description('Name of the private endpoint subnet')
param peSubnetName string = 'pe-subnet'

