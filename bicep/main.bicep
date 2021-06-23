param location string
param alias string
param vmSize string = 'Standard_DS3_v2'
param adminUserName string
param adminPassword string
param sshPublicKey string
param scriptUri string
param imageRef object = {
  offer: '0001-com-ubuntu-server-focal'
  publisher: 'Canonical'
  sku: '20_04-lts'
  version: 'latest'
}

var resourceGroupName = 'k9s-arc-workshop-${alias}-rg'
var vnetName = 'k8s-vnet-${alias}'
var subnetName = 'k8s-subnet'
var vmName = 'k8s-master'
var nicName = '${vmName}-nic'
var publicIpAddressName = '${vmName}-vip'
var publicIpAddressDnsName = 'k8s-master-lab-${alias}'

module resourceGroupModule 'resourceGroup.bicep' = {
  name: 'resourceGroupDeployment'
  scope: subscription()
  params: {
    location: location
    name: resourceGroupName
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  dependsOn: [
    resourceGroupModule
  ]
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '172.10.0.0/24'
        }
      }
    ]
  }
}

resource vmPublicIpAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  dependsOn: [
    resourceGroupModule
  ]
  location: location
  name: publicIpAddressName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: publicIpAddressDnsName
    }
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  location: location
  name: nicName
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          publicIPAddress: {
            id: vmPublicIpAddress.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: vmName
  properties: {
    storageProfile: {
      imageReference: imageRef
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          createOption: 'Empty'
          diskSizeGB: 10
          lun: 1
        }
      ]
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    osProfile: {
      adminPassword: adminPassword
      adminUsername: adminUserName
      computerName: vmName
      linuxConfiguration: {
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUserName}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
      }
    }
  }
}

resource scriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vm
  name: 'k8ssetup'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    protectedSettings: {
      commandToExecute: '<command-to-execute>'
      //script: 'base64-script-to-execute>'
      storageAccountName: ''
      storageAccountKey: ''
      fileUris: [
        scriptUri
      ]
      managedIdentity: ''
    }
  }
}

output sshCommand string = 'ssh ${adminUserName}@${vmPublicIpAddress.properties.dnsSettings.fqdn}'
